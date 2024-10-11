# Use the toroio/martini-runtime:${MARTINI_VERSION} image as the base
ARG MARTINI_VERSION
FROM toroio/martini-runtime:${MARTINI_VERSION}

# Copy packages to the MR image
COPY packages /data/packages

# Set the working directory
WORKDIR /data
