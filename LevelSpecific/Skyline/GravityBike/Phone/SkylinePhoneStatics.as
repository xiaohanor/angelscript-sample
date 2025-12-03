namespace GravityBikeSpline::Phone
{
	AHazePlayerCharacter GetPlayer()
	{
		return Game::Zoe;
	}

	USkylinePhoneUserComponent GetPlayerComponent()
	{
		return USkylinePhoneUserComponent::Get(GetPlayer());
	}

	UFUNCTION(BlueprintPure)
	bool IsPhoneGameComplete()
	{
		return GetPlayerComponent().Phone.bPhoneCompleted;
	}

	UFUNCTION(BlueprintPure)
	bool IsPhoneGameActive()
	{
		if(GetPlayerComponent().Phone == nullptr)
			return false;
		
		return GetPlayerComponent().Phone.bGameStarted;
	}

	UFUNCTION(BlueprintCallable)
	void HidePhone(FInstigator Instigator)
	{
		GetPlayerComponent().Phone.AddActorVisualsBlock(Instigator);
	}

	UFUNCTION(BlueprintPure)
	ASkylinePhoneBase GetOrCreatePhone()
	{
		if(GetPlayerComponent().Phone == nullptr)
		{
			return GetPlayerComponent().SpawnPhone();
		}

		return GetPlayerComponent().Phone;
	}

	UFUNCTION(BlueprintCallable)
	void SavePhoneGameProgress()
	{
		USkylinePhoneUserComponent PlayerComp = GetPlayerComponent();
		PlayerComp.SavePhoneGameProgress();
	}

	UFUNCTION(BlueprintCallable)
	void ResetPhoneGameProgress()
	{
		USkylinePhoneUserComponent PlayerComp = GetPlayerComponent();
		PlayerComp.ResetPhoneGameProgress();
	}

	/**
	 * FB TODO: Replace with starting a sheet?
	 */
	UFUNCTION(BlueprintCallable)
	void SetUsePhoneView(bool bUsePhoneView, bool bSnapCamera = true)
	{
		USkylinePhoneUserComponent PlayerComp = GetPlayerComponent();
		if(PlayerComp.bUsePhoneView == bUsePhoneView)
			return;

		PlayerComp.bUsePhoneView = bUsePhoneView;
		PlayerComp.bSnapPhoneView = bSnapCamera;
	}
};