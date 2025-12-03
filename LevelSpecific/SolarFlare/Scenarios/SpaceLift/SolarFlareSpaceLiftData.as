namespace SolarFlareSpaceLiftData
{
	const int Stage2 = 2;
	const int Stage3 = 4;
	const int Stage4 = 6;

	bool IsStageApplicable(int Stage, int Index)
	{
		switch(Stage)
		{
			case 1:
				if (Index < Stage2)
					return true;
				break;
			case 2:
				if (Index >= Stage2 && Index < Stage3)
					return true;
				break;
			case 3:
				if (Index >= Stage3 && Index < Stage4)
					return true;
				break;
			case 4:
				if (Index >= Stage4)
					return true;
				break;
		}

		return false;
	}
}