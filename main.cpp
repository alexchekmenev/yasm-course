#include <iostream>
#include <cstdio>
#include <string>
#include <vector>
#include <algorithm>
#include <cassert>
#include "suffix-array.h"
#include <cstdlib>

using namespace std;

#define mp make_pair
#define pb push_back

void suffix_array(const string& s, vector <int>& p) {
    int n = s.size();
    p.resize(n, 0);
    int sz = max(n, 256);
    vector <int> sum(sz, 0), h(sz, 0), c(sz, 0), c_n(sz, 0), p_n(n, 0);

    for(int i = 0; i < n; i++) {
        c[i] = s[i];
        sum[c[i]]++;
    }
    int ptr = 0;
    for(int i = 1; i < sz; i++) {
        h[i] = h[i - 1] + sum[i - 1];
    }
    for(int i = 0; i < n; i++) {
        p[h[c[i]]] = i;
        h[c[i]]++;
    }

    h[0] = 0;
    c_n[p[0]] = 0;
    for(int i = 1; i < n; i++) {
        if (c[p[i]] != c[p[i - 1]]) {
            c_n[p[i]] = c_n[p[i - 1]] + 1;
            h[c_n[p[i]]] = i;
        } else {
            c_n[p[i]] = c_n[p[i - 1]];
        }
    }
    c = c_n;

    for(int l = 1; l < n; l *= 2) {
        /*cout << "l = " << l << ":\n";
        cout << "c   - [";
        for(int j = 0; j < n; j++) {
            cout << c[j] << " ";
        }
        cout << "]\n";*/

        for(int i = 0; i < n; i++) {
            p_n[i] = (n + p[i] - l) % n;
        }

        /*cout << "p_n - [";
        for(int j = 0; j < n; j++) {
            cout << p_n[j] << " ";
        }
        cout << "]\n";

        cout << "h   - [";
        for(int j = 0; j < n; j++) {
            cout << h[j] << " ";
        }
        cout << "]\n";*/

        for(int i = 0; i < n; i++) {
            p[h[c[p_n[i]]]] = p_n[i];
            h[c[p_n[i]]]++;
        }

        /*cout << "p   - [";
        for(int j = 0; j < n; j++) {
            cout << p[j] << " ";
        }
        cout << "]\n";*/

        c_n[p[0]] = 0;
        h[0] = 0;
        for(int i = 1; i < n; i++) {
            int p1 = p[i], p2 = (p1 + l) % n;
            int pr1 = p[i - 1], pr2 = (pr1 + l) % n;
            if (c[pr1] != c[p1] || c[pr2] != c[p2]) {
                c_n[p1] = c_n[pr1] + 1;
                h[c_n[pr1] + 1] = i;
            } else {
                c_n[p1] = c_n[pr1];
            }
        }

        /*cout << "c_n - [";
        for(int j = 0; j < n; j++) {
            cout << c_n[j] << " ";
        }
        cout << "]\n";*/

        c = c_n;
        //cout << endl;
    }
}

string s;

int main() {
    //ios_base::sync_with_stdio(false);

    //freopen("array.in", "r", stdin);
    //freopen("array.out", "w", stdout);

    int n = 1000000;
    s.resize(n);
    srand(time(NULL));
    for(int i = 0; i < n; i++) {
        s[i] = char(rand() % 26 + 'a');
    }
    s += "#";

    vector <int> sa(n + 1, 0);

    cout << "C++ implementation:\n";
    int cpp_cl = clock();
    suffix_array(s, sa);
    cpp_cl = clock() - cpp_cl;
    printf("time = %.3lf\n", 1.0*cpp_cl / 1000000);

    cout << "YASM implementation:\n";
    int asm_cl = clock();
    SuffixArray a = buildSuffixArray(s.c_str(), s.size());
    asm_cl = clock() - asm_cl;
    printf("time = %.3lf\n", 1.0*asm_cl / 1000000);

    for(int i = 1; i < s.size(); i++) {
        if (sa[i] != getPosition(a, i)) {
            cout << "pizda v pozicii i = " << i << endl;
            break;
        }
    }

    deleteSuffixArray(a);
    return 0;
}
