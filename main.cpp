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
        for(int i = 0; i < n; i++) {
            p_n[i] = (n + p[i] - l) % n;
        }

        for(int i = 0; i < n; i++) {
            p[h[c[p_n[i]]]] = p_n[i];
            h[c[p_n[i]]]++;
        }

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
        c = c_n;
    }
}

bool check_impls(vector<int>& cpp_sa, SuffixArray asm_sa) {
    int n = cpp_sa.size();
    for(int i = 0; i < n; i++) {
        if (cpp_sa[i] != getPosition(asm_sa, i)) {
            return false;
        }
    }
    return true;
}

void generate_string(string& s, int n) {
    s.resize(n);
    srand(time(NULL));
    for(int i = 0; i < n; i++) {
        s[i] = char(rand() % 26 + 'a');
    }
}

vector<int> findAll(string& s, string& q) {
    vector <int> entries;
    int ptr = -1, last = -1;
    while((ptr = s.find(q, last + 1)) != -1) {
        entries.pb(ptr);
        last = ptr;
    }
    return entries;
}

string s, q;

int main() {
    //ios_base::sync_with_stdio(false);

    //freopen("array.in", "r", stdin);
    //freopen("array.out", "w", stdout);

    int n = 50;
    cin >> n;
    //n = s.size();
    generate_string(s, n);
    cout << "s = " << s.substr(0, min(50, (int)s.size())) << (s.size() > 50 ? "...\n" : "\n");
    vector <int> sa(n, 0);

    /* cpp building */
    int cpp_cl = clock();
    suffix_array(s, sa);
    cpp_cl = clock() - cpp_cl;
    printf("cpp:build - %.3lf s\n", 1.0*cpp_cl / 1000000);

    /* asm building */
    int asm_cl = clock();
    SuffixArray a = buildSuffixArray(s.c_str(), s.size());
    asm_cl = clock() - asm_cl;
    printf("asm:build - %.3lf s\n", 1.0*asm_cl / 1000000);

    if (!check_impls(sa, a)) {
        cout << "asm:build - wrong SuffixArray\n";
    } else {
        while(cin >> q) {
            Range r = findAllEntries(a, q.c_str(), q.size());
            int first = getRangeFirst(r), last = getRangeLast(r);
            //cout << "first = " << first << ", last = " << last << endl;
            if (first == last) {
                cout << "No entries\n";
            } else {
                vector <int> asm_e, cpp_e;
                cpp_e = findAll(s, q);
                for(int i = first; i < last; i++) {
                    asm_e.pb(getPosition(a, i));
                    //cout << asm_e.back() << endl;
                }
                sort(asm_e.begin(), asm_e.end());

                if (cpp_e != asm_e) {
                    cout << "cpp finds - " << cpp_e.size() << ", but asm finds - " << asm_e.size() << " entries\n";
                }
                if (1) {
                    cout << "Entries: " << (last - first) << " entries were found\n";
                    for(int i = 0; i < min((int)asm_e.size(), 10); i++) {
                        int l = asm_e[i];
                        int rr = min((int)s.size(), l + 10);;
                        cout << "\t" << s.substr(l, rr - l) << "\n";
                    }
                    cout << endl;
                }
            }
            deleteRange(r);
        }
    }
    deleteSuffixArray(a);

    return 0;
}
