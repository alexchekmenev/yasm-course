#include <iostream>
#include <cstdio>
#include <string>
#include <vector>
#include <algorithm>
#include <cassert>
#include "suffix-array.h"

using namespace std;

#define mp make_pair
#define pb push_back

void print(vector<int>& a, int n, string name) {
    cout << name << ": ";
    for(int i = 0; i < n; i++) {
        cout << a[i] << " ";
    }
    cout << endl;
}

vector <int> suffix_array(const string& s) {
    int n = s.size();
    int sz = max(n, 256);
    vector <int> sum(sz, 0), h(sz, 0), c(sz, 0), c_n(sz, 0), p(n, 0), p_n(n, 0);

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

    //print(p, n, "p0");

    for(int l = 1; l < n; l *= 2) {

        for(int i = 0; i < n; i++) {
            p_n[i] = (n + p[i] - l) % n;
        }
        for(int i = 0; i < n; i++) {
            p[h[c[p_n[i]]]] = p_n[i];
            h[c[p_n[i]]]++;
        }
        //print(p, n, "p");

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

        //print(h, n, "h");
        c = c_n;
    }
    return p;
}


int main() {
    //ios_base::sync_with_stdio(false);

    freopen("array.in", "r", stdin);
    //freopen("array.out", "w", stdout);

    string s;
    cin >> s;
    s += "#";

    vector <int> sa = suffix_array(s);
    cout << "C++ implementation:\n";
    for(int i = 1; i < (int)sa.size(); i++) {
        cout << sa[i] + 1 << " ";
    }
    cout << endl;

    cout << "YASM implementation:\n";
    /*int a = buildSuffixArray(s.c_str(), s.size());
    cout << "\nA = " << a << endl << endl;*/
    SuffixArray a = buildSuffixArray(s.c_str(), s.size());
    for(int i = 0; i < s.size(); i++) {
        cout << getPosition(a, i) << endl;
    }
    assert(a != NULL);
    deleteSuffixArray(a);
    return 0;
}
