// Notkun: queuetest < INN > UT
// Fyrir:  INN inniheldur allt a� 1000 fleytit�lur � textasni�i
// Eftir:  UT inniheldur s�mu t�lur � s�mu r��

// H�fundur: Snorri Agnarsson

// �etta forrit ���ist � minni v�l undir Cygwin, me� skipuninni
//    g++ -o queuetest.exe queuetest.C

#include "queuearray.h"
#include "queuechain.h"
#include <iostream>

using namespace std;

// Notkun: main();
// Fyrir:  A�alinntak inniheldur allt a� 1000 fleytit�lur.
// Eftir:  B�i� er a� lesa t�lurnar og skrifa ��r � lesr��
//         � a�al�ttak.
int main() {
    queuearray<double,1000> q;
    while(1) {
        // B�i� er a� lesa n�ll e�a fleiri fleytit�lur, 
        // og q inniheldur ��r � lestrarr��.
        double x;
        if( cin >> x )
            q.Put(x);
        else
            break;
    }
    queuechain<double> q2;
    while( q.Count()!=0 ) q2.Put(q.Get());
    while( q2.Count()!=0 ) q.Put(q2.Get());
    while( q.Count() != 0 ) {
        // B�i� er a� skrifa n�ll e�a fleiri fremstu lesnu
        // t�lurnar, hinar eru � lestrarr�� � q.
        cout << q.Get() << endl;
    }
}
