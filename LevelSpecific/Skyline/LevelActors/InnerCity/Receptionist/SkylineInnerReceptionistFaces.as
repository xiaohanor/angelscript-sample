namespace SkylineInnerReceptionistFaces
{
	const bool o = false;
	const int MouthStartIndex = 8;

	// don't judge me ok
	void SetRow(FSkylineInnerReceptionistPixelRowExpression& OutData,
	bool bLit, bool bLit1, bool bLit2, bool bLit3,
	bool bLit4, bool bLit5, bool bLit6, bool bLit7,
	bool bLit8, bool bLit9, bool bLit10, bool bLit11,
	bool bLit12, bool bLit13, bool bLit14, bool bLit15)
	{
		OutData.Lits[0] = bLit;
		OutData.Lits[1] = bLit1;
		OutData.Lits[2] = bLit2;
		OutData.Lits[3] = bLit3;
		OutData.Lits[4] = bLit4;
		OutData.Lits[5] = bLit5;
		OutData.Lits[6] = bLit6;
		OutData.Lits[7] = bLit7;
		OutData.Lits[8] = bLit8;
		OutData.Lits[9] = bLit9;
		OutData.Lits[10] = bLit10;
		OutData.Lits[11] = bLit11;
		OutData.Lits[12] = bLit12;
		OutData.Lits[13] = bLit13;
		OutData.Lits[14] = bLit14;
		OutData.Lits[15] = bLit15;
	}

	void EyesNormal(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
	}

	void EyesNormalLeft(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o           ); Index++;
	}

	void EyesNormalRight(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o, o           ); Index++;
	}

	void EyesNormalDown(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, Z, o, o, o, o, Z, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
	}

	void EyesBlink1(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
	}

	void EyesBlink2(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, Z, o, o, o, o, Z, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
	}

	void EyesHappy(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesCrocs(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, o, o, o, o, o, o, o, o, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, Z, o, o, Z, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, o, o, o, o, o, o, o, o, Z, Z, o, o           ); Index++;
	}

	void EyesCrocPeek(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, Z, o, o, o, Z, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, o, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
	}

	void EyesCrocPeek2(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, o, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, Z, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, o, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
	}

	void EyesOuch(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, o, o, o, o, o, o, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, o, o, o, o, o, o, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesX(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesUU(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesPouty(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, o, o, o, Z, Z, Z, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesPoutyRight(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, o, o, o, Z, Z, Z, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, o, o, o, o, o, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesPoutyLeft(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, o, o, o, Z, Z, Z, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesPoutyUp(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, o, o, o, o, Z, Z, Z, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, Z, o, o, o, o, o, o, Z, o, o, Z, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesPoutyUpLeft(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, o, o, o, o, Z, Z, Z, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, Z, o, o, o, o, o, o, o, Z, o, Z, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesPoutyUpRight(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, o, o, o, o, Z, Z, Z, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, o, o, o, o, o, o, o, Z, o, o, Z, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void EyesBrows1(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, Z, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, o, o, o, Z, o, o, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}	

	void EyesBrows2(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, Z, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, o, o, o, Z, o, o, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}	

	void EyesWorried(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, o, o, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, o, Z, o, o, o, o, Z, o, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, o, o, Z, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
	}	

	void EyesShocked(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, o, o, o, o, o, o, o, o, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, o, o, o, o, o, o, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, o, o, o, o, o, o, Z, Z, o, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, o, o, o, o, o, o, o, o, o, o, Z, o, o           ); Index++;
	}

	void EyesAfraid(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, o, o, o, o, o, o, o, o, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, o, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, o, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, o, o, o, o, o, o, o, o, Z, o, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, o, o, o, o, o, o, o, o, o, o, Z, Z, o           ); Index++;
	}	

	void EyesSunglasses(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, Z, Z, Z, o, o, Z, Z, Z, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, Z, Z, Z, o, o, Z, Z, Z, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, Z, o, o, o, o, Z, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	// ---------------------------

	void MouthSmile(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, o, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, Z, Z, Z, Z, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthSmallSmile(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, o, o, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthHello(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthP1(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, Z, Z, Z, Z, Z, Z, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthP2(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, Z, Z, Z, Z, Z, Z, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthOhNo(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthOhNoHigh(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthO(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthSmirk(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthPouty(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, Z, Z, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthBlank(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthV(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, Z, o, o, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, o, o, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void MouthTeeth(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = MouthStartIndex;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, Z, o, Z, o, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	UFUNCTION()
	void CatFace1(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, Z, Z, o, o, o, o, Z, Z, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, o, Z, Z, o, o, Z, Z, o, Z, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, o, o, o, Z, o, o, Z, o, o, o, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, o, o, o, Z, o, o, Z, o, o, o, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, o, Z, Z, o, o, Z, Z, o, Z, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, Z, Z, o, o, o, o, Z, Z, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, o, Z, Z, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, o, Z, o, o, Z, o, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void CatFace2(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, Z, Z, o, o, o, o, Z, Z, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, o, o, Z, Z, Z, Z, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, o, o, Z, Z, Z, Z, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, Z, Z, Z, o, o, o, o, Z, Z, Z, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, o, Z, Z, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, o, Z, o, o, Z, o, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void CatFace3(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, o, o, Z, Z, Z, Z, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, o, o, Z, Z, Z, Z, Z, Z, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, o, Z, Z, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, o, Z, o, o, Z, o, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void FacexD1(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, Z, o, o, o, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, Z, o, o, o, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, Z, o, o, o, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, Z, o, o, o, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, Z, o, o, o, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, Z, o, o, o, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, Z, o, o, o, o, Z, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void FacexD2(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, Z, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, o, o, Z, o, o, Z, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, Z, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, o, o, o, Z, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, o, o, o, Z, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, Z, o, o, o, Z, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, Z, o, Z, o, o, Z, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, Z, o, o, Z, o, o, Z, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, o, o, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, Z, Z, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}

	void FaceQuestionmark(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, Z, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, Z, Z, o, o, Z, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, Z, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, Z, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, Z, Z, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}	

	void FaceInterrobang(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, Z, Z, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, Z, Z, o, o, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, o, o, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, o, o, Z, Z, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, Z, Z, Z, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, Z, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, Z, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, Z, Z, o, o, o, Z, Z, o, o, o, o, o           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o           ); Index++;
	}	

	void FaceLoading1(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o,           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o,           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o,           ); Index++;
	}	

	void FaceLoading2(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o,           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o,           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o,           ); Index++;
	}	

	void FaceLoading3(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o,           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o,           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o,           ); Index++;
	}

	void FaceLoading4(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o,           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, o,           ); Index++;
		SetRow(Out[Index],             o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o,           ); Index++;
		SetRow(Out[Index],             o, o, o, o, o, o, o, o, o, o, o, o, o, o, o, o,           ); Index++;
	}

	void FaceExterminate1(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, Z, Z, Z, Z, Z, Z, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, Z, Z, o, o, Z, Z, o, o, Z, Z, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, Z, Z, o, Z, Z, Z, Z, o, Z, Z, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, o, o, Z, Z, Z, Z, Z, Z, o, o, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, Z, Z, Z, Z, Z, Z, Z, Z, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, o, o, o, o, o, o, o, o, o, o, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
	}

	void FaceExterminate2(TArray<FSkylineInnerReceptionistPixelRowExpression>& Out)
	{
		const bool Z = true;
		int Index = 0;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, Z, Z, o, o, Z, Z, o, o, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, Z, Z, o, Z, Z, Z, o, o, Z, Z, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, o, o, Z, Z, Z, Z, Z, o, Z, Z, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, o, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, o, o, o, o, o, o, o, o, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, o, o, Z, Z, Z, Z, Z, Z, Z, Z, o, o, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, o, o, o, o, o, o, o, o, o, Z, Z, Z, Z           ); Index++;
		SetRow(Out[Index],             Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z, Z           ); Index++;
	}
}