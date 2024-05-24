#!/bin/bash

for i in $(ls diagrams/*.mmd); do
    mmdc -i ${i} -o ${i%.*}.svg
done