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

I think this gem should probably implement an active record object called `Bai2::BaiFile` (or some-such) that we can pass a `File` object to and which will then save and parse the BAI2 file text, perform some check-sums, and expose all the data as properties.

Example usage:

```
```

## References

I was able to find one gem that parses BAI files. However, it has no tests and does not seem to check the various checksums that are available in the actual BAI format. You can start with that or just build this yourself:

[bai_parser](https://github.com/sanjp/bai_parser)

[bai_parser.rb (the interesting code)](https://github.com/sanjp/bai_parser/blob/master/lib%2Fbai_parser.rb)
