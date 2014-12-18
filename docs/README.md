#### Chase guide
Some of the more straightforward documentation I've been able to find on BAI2 files. However, it is specific to Chase bank, so there are one or two fields for which they just say "We always put a 1 here". That may not be the case at SVB.

#### Daily_BAI2_Account_sample.txt
This is a sample file from SVB of the "morning" BAI2 file. We should be able to parse out our entire account balance, here. It will also have:

1. A reference to all the wires that went into or out of this account yesterday.
2. A lump transaction for each type of ACH file that we've sent to them.
3. Individual lines for all incoming ACH pushes (credits) to our account.

#### EOD_BAI2_wire_info_sample.TXT
This is the "End-of-Day" BAI2 file that SVB puts together around 5pm. We will not want to get the account balance from this file, but what it does provide is very detailed records on all the incoming or outgoing wires that happened /today/ to this account.

#### External docs

I'm currently reading: http://www.bai.org/Libraries/Site-General-Downloads/Cash_Management_2005.sflb.ashx Looks like this may be the latest official spec?
