#ifndef ARRAY_H_
#define ARRAY_H_
#pragma once
#include <iostream>

// template <class T> class Array;
using namespace std;

template <class T>
class Array {
public:
	// deep copy constructor
	Array(const Array<T>& rhs) {
		m_Size = rhs.size();
		m_Data = new T[m_Size];
		if (!m_Data) {
			cerr << "Could not allocate memory for array of size "
				 << m_Size << "\n";
			abort();
		}
		for (int i=0; i<m_Size; i++) {
			m_Data[i] = rhs[i];
		}
	}
	
	// copy construct from part of an array
	Array(const Array<T> & a, int start, int n) {
		if (n<1) {
			cerr << "Illegal Array m_Size " << n << "\n";
			abort();
		}
		m_Size = n;
		m_Data = new T[m_Size];
			if (!m_Data) {
			cerr << "Could not allocate memory for array of size "
				 << n << "\n";
			abort();
		}
		for (int i=0; i<m_Size; i++) {
			T test = a[i+start];
			m_Data[i] = test;
		}
	}
	
	Array(const T a[], int n) {
		if (n<1) {
			cerr << "Illegal Array m_Size " << n << "\n";
			abort();
		}
		m_Size = n;
		m_Data = new T[m_Size];
			if (!m_Data) {
			cerr << "Could not allocate memory for array of size "
				 << n << "\n";
			abort();
		}
		for (int i=0; i<m_Size; i++) {
			T test = a[i];
			m_Data[i] = test;
		}
	}
	Array() { // default constructor, makes an empty array
        m_Data = 0;
        m_Size = 0;
    };
	void SetSize(int n) {
		if (m_Data != 0) {
			       // cout << "m_Size=" << m_Size << "; n=" << n << "\n";
			if (m_Size <= 0) {
				cerr << "prevent deletion of uninitialized store\n";
				abort();
			}
			delete[] m_Data; // delete old data if there is any
		}
		if (n<1) {
			cerr << "Illegal Array m_Size " << n << "\n";
			abort();
		}
		m_Size = n;
		m_Data = new T[m_Size];
		if (!m_Data) {
			cerr << "Could not allocate memory for array of size "
				 << n << "\n";
			abort();
		}
	}
	Array(int n) {
		if (n<1) {
			cerr << "Illegal Array m_Size " << n << "\n";
			abort();
		}
		m_Size = n;
		m_Data = new T[m_Size];
		if (!m_Data) {
			cerr << "Could not allocate memory for array of size "
				 << n << "\n";
			abort();
		}
	}
	~Array() {
		delete []m_Data;
	}
	int size() const {
		return m_Size;
	}
	inline T& operator[](int i) const {
        // too slow for hundred-thousands of calls
		/*if (i<0 || i>=m_Size) {
			cerr << "Array index " << i << " out of bounds!\n";
			abort();
		}*/
		return (m_Data[i]);
	}
	// m_Data should really be private and accessed through the [] operator
	T *m_Data;
 private:
	int m_Size;
};

template <class T>
class Array2 {
public:
	Array2(int n1, int n2) {
		if (n1<1 || n2<1) {
			cerr << "Illegal 2D Array m_Size " << n1 << "x" << n2 << "\n";
			abort();
		}
		nrow = n1;
		ncol = n2;
		m_Data2 = new Array<T> *[nrow];
		if (!m_Data2) {
			cerr << "Could not allocate memory for 2D array of size "
				 << n1 << "x" << n2 << "\n";
			abort();
		}	
		for(int i=0; i<nrow; i++) {
			m_Data2[i] = new Array<T>(ncol);
				if (!m_Data2[i]) {
					cerr << "Could not allocate memory for 2D array of size "
						 << n1 << "x" << n2 << "\n";
				abort();
			}	
		}
	}
	~Array2() {
		for(int i=0; i<nrow; i++) {
			delete (m_Data2[i]);
		}
		delete[] m_Data2;
	}
	const int nRows() const {
		return nrow;
	}
	const int nCols() const {
		return ncol;
	}
	Array<T>& operator[](const int i) const {
		/*if (i<0 || i>=nrow) {
			cerr << "2D Array index " << i << " out of bounds!\n";
			abort();
		}*/
		return (*(m_Data2[i]));
	}
 private:
	Array<T> **m_Data2;
	int nrow, ncol;
};

#endif /*ARRAY_H_*/
