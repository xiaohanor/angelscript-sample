enum EMonkeyCongaStage
{
	SimonSays,
	CongaLine,
	DanceShowdown
}

struct FMonkeyCongaCrowdMonkeyAnimData
{
	EMonkeyCongaStage Stage = EMonkeyCongaStage::SimonSays;
	bool bFail;
	bool bSuccess;
}

UCLASS(Abstract)
class ADanceShowdownCrowdMonkey : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)	
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UHazeCharacterSkeletalMeshComponent MeshComp;

	UPROPERTY(EditAnywhere)
	ULocomotionFeatureMonkeyCrowd AnimationFeature;

	UPROPERTY(EditAnywhere)
	bool bStageMonkey = true;

	UPROPERTY(EditInstanceOnly)
	bool bIsDJ = false;

	FMonkeyCongaCrowdMonkeyAnimData AnimData;


	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TundraSimonSays::GetManager().OnEitherPlayerFailed.AddUFunction(this, n"OnFail");
		TundraSimonSays::GetManager().OnBothPlayersSuccessful.AddUFunction(this, n"OnSuccess");
		TundraSimonSays::GetManager().OnNextStage.AddUFunction(this, n"OnNextStage");

		CongaLine::GetManager().OnCongaStartedEvent.AddUFunction(this, n"OnCongaLineStarted");
		CongaLine::GetManager().OnCongaStartedEvent.AddUFunction(this, n"OnCongaLineStarted");
		DanceShowdown::GetManager().OnGameStartedEvent.AddUFunction(this, n"OnDanceShowdownStarted");
		DanceShowdown::GetManager().OnPlayerFail.AddUFunction(this, n"OnFail");
		DanceShowdown::GetManager().OnMonkeyRecovery.AddUFunction(this, n"StopFail");
		DanceShowdown::GetManager().OnPlayerSuccess.AddUFunction(this, n"OnSuccess");
		DanceShowdown::GetManager().OnStopFlourish.AddUFunction(this, n"StopSuccess");
		
		
		if(bStageMonkey)
		{
			DanceShowdown::GetManager().CrowdMonkeyManager.ShowStageCrowdActorsEvent.AddUFunction(this, n"Show");
			DanceShowdown::GetManager().CrowdMonkeyManager.HideStageCrowdActorsEvent.AddUFunction(this, n"Hide");
		}
		else
		{
			DanceShowdown::GetManager().CrowdMonkeyManager.ShowCrowdActorsEvent.AddUFunction(this, n"Show");
			DanceShowdown::GetManager().CrowdMonkeyManager.HideCrowdActorsEvent.AddUFunction(this, n"Hide");
		}
		
		Hide();
		SetActorHiddenInGame(false);
	}

	UFUNCTION()
	private void OnNextStage(int NewStageIndex)
	{
		StopSuccess();
	}

	UFUNCTION()
	private void StopSuccess()
	{
		AnimData.bSuccess = false;
	}

	UFUNCTION()
	private void OnSuccess()
	{
		AnimData.bSuccess = true;
		AnimData.bFail = false;
	}

	UFUNCTION()
	private void StopFail()
	{
		AnimData.bFail = false;
	}

	UFUNCTION()
	private void OnFail()
	{
		AnimData.bFail = true;
		AnimData.bSuccess = false;
	}

	UFUNCTION()
	private void OnCongaLineStarted()
	{
		AnimData.Stage = EMonkeyCongaStage::CongaLine;
	}

	UFUNCTION()
	private void OnDanceShowdownStarted()
	{
		AnimData.Stage = EMonkeyCongaStage::DanceShowdown;
	}

	UFUNCTION()
	void Hide()
	{
		MeshComp.SetVisibility(false);
	}

	UFUNCTION()
	void Show()
	{
		MeshComp.SetVisibility(true);
	}
};
