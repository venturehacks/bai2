bai2_file
=========

This gem parses BAI2 files that we receive from a bank.

## Background

### What is a BAI2 file?

The BAI2 file format is used by banks to provide batched updates about transactions in an account. [Wikipedia has an overview](https://en.wikipedia.org/wiki/BAI_(file_format)).

I have a PDF from Chase bank as well, which I will add to this repository.

### When do we need it?

We receive two BAI2 files per day. One of them comes in at the end of the day (~5pm) and contains very detailed information about all the wires that have been processed during the day. The other comes in every morning (~6am) and contains a final accounting of all incoming and outgoing wires and other transfers. It also contains a total account balance.

Therefore, during the afternoon job, we will use the information to create `Wire` objects in our database. During the morning job, we will match up with these wires and credit the funds to them. In the morning job, we will also use the sum total of the recent ACH transactions to compare to the ACH file that we uploaded the day before. Finally, the morning job will also contain individual incoming ACHes. We will need to use those to create transactions in our DB as well.

## API

