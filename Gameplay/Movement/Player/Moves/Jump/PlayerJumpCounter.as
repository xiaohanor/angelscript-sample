class UPlayerJumpCounter : UHazeSingleton
{
	int TotalJumps = -1;
	
	void IncrementJump()
	{
		if(TotalJumps == -1)
		{
			if(Progress::HasActivatedAnyProgressPoint())
			{
				TotalJumps = Save::GetPersistentProfileCounter(n"TotalJumps");
			}
			else
			{
				TotalJumps = 0;
			}
		}

		++TotalJumps;

		if(Save::CanAccessProfileData())
		{
			Save::ModifyPersistentProfileCounter(n"TotalJumps", TotalJumps);
		}
	}
}
