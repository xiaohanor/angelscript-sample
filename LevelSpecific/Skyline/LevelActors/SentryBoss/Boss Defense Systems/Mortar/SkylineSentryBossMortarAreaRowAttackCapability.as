class USkylineSentryBossMortarAreaRowAttackCapability : UHazeCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);

	default TickGroup = EHazeTickGroup::Gameplay;

	ASkylineSentryBossMortarArea MortarArea;
	int CurrentRow;
	//float RowAttackCooldown = 0.6;
	float TimeToRowAttack;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		MortarArea = Cast<ASkylineSentryBossMortarArea>(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if(MortarArea.bRowAttack)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(MortarArea.bRowAttack)
			return false;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
		if(MortarArea.bReverseAttack)
			CurrentRow = 0;
		else
			CurrentRow = MortarArea.Collumns;

		TimeToRowAttack = Time::GameTimeSeconds + MortarArea.RowAttackCooldown;
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(TimeToRowAttack > Time::GameTimeSeconds)
			return;

		// for(int i = 0; i < MortarArea.Rows; i++)
		// {		
		// 	MortarArea.SpawnMortarAtPosition(i, MortarArea.CurrentRow);
		// }

		for(ASkylineSentryBossMortar Mortar : MortarArea.MortarActors)
		{
			if(Mortar.Row == CurrentRow)
			{
				Mortar.Activate();
			}
		}

		if(MortarArea.bReverseAttack)
			CurrentRow++;
		else
			CurrentRow--;

		if(CurrentRow <= 0 || CurrentRow >= MortarArea.Collumns)
			MortarArea.bRowAttack = false;
		

		TimeToRowAttack = Time::GameTimeSeconds + MortarArea.RowAttackCooldown;
	}

};