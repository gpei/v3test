

number=$(cat /home/pei/Desktop/jmeter.jtl |wc -l)
#number=$(awk -F "," '{print $2}' /home/pei/Desktop/jmeter.jtl|wc|awk '{print $1}')

Average=$(awk -F "," '{print $2}' /home/pei/Desktop/jmeter.jtl | awk '{sum+=$1}END{print sum/NR}')

Min=$(awk -F "," '{print $2}' /home/pei/Desktop/jmeter.jtl |sort -nr | sed -n '1p')

Max=$(awk -F "," '{print $2}' /home/pei/Desktop/jmeter.jtl |sort -nr | sed -n '$p')

N50=$number*0.5
N90=$number*0.9

Medium=$(awk -F "," '{print $2}' /home/pei/Desktop/jmeter.jtl|sort -n| awk "NR==$N50" )
Line90=$(awk -F "," '{print $2}' /home/pei/Desktop/jmeter.jtl|sort -n| awk "NR==$N90" )


Success_number=$(grep OK /home/pei/Desktop/jmeter.jtl |wc -l)
if [ $Success_number -eq $number ]
  then
      echo "All success!"
  else
      echo "Error happened..."
fi      

echo "AVG=$Average , Min=$Min , Max=$Max , Medium=$Medium 90%Line=$Line90"
