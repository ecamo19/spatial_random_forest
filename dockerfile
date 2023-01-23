# Use Ubuntu as the base image
FROM ubuntu:latest

# Install conda
RUN apt-get update && \
    apt-get install -y wget bzip2 && \
    wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -b -p /miniconda3 && \
    rm Miniconda3-latest-Linux-x86_64.sh

# Add conda to PATH
ENV PATH="/miniconda3/bin:$PATH"

# Create a new conda environment and install snakemake
RUN conda create -n snakemake python=3.8 snakemake && \
    echo "source activate snakemake" > ~/.bashrc

# Install any other necessary dependencies for your pipeline
RUN conda install -n snakemake <dependency1> <dependency2> ...

# Copy your code and Snakefile into the container
COPY . .

# Set the working directory
WORKDIR /app

# Run snakemake
CMD ["snakemake"]
