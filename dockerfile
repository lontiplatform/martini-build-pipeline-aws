# Use the toroio/martini-runtime:${MARTINI_VERSION} image as the base
ARG MARTINI_VERSION
FROM toroio/martini-runtime:${MARTINI_VERSION}

# Set a writable directory for logs in AWS Lambda
ENV LOG_DIR=/tmp/logs

# Update the JAVA_OPTS to write GC logs to the writable directory
ENV JAVA_OPTS="-Xlog:gc*=debug:file=${LOG_DIR}/gc.log:time,uptime,level,tags:filecount=10,filesize=10M:age*=debug"

# Ensure the writable directory exists
RUN mkdir -p /tmp/logs

# Copy packages to the MR image
COPY packages /data/packages

# Set the working directory
WORKDIR /data

# Ensure the default command runs as expected
CMD ["bin/toro-martini"]
