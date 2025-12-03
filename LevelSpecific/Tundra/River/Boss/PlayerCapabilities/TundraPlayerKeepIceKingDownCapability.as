struct FKeepIceKingDownParams
{
	bool bShouldActivateCapability = false;
	ATundraBoss Boss;
}

struct FKeepIceKingDownActivationParams
{
	ATundraBoss Boss;
}

class UTundraPlayerKeepIceKingDownComponent : UActorComponent
{
	FKeepIceKingDownParams KeepIceKingDownParams;
	bool bIsMashingSufficient = true;
};

class UTundraPlayerKeepIceKingDownCapability : UHazePlayerCapability
{
	default CapabilityTags.Add(CapabilityTags::GameplayAction);
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::Gameplay;

	UTundraPlayerKeepIceKingDownComponent Comp;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		Comp = UTundraPlayerKeepIceKingDownComponent::GetOrCreate(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FKeepIceKingDownActivationParams& Params) const
	{
		if(!Comp.KeepIceKingDownParams.bShouldActivateCapability)
			return false;

		if(Comp.KeepIceKingDownParams.Boss == nullptr)
			return false;

		Params.Boss = Comp.KeepIceKingDownParams.Boss;

		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(!Comp.KeepIceKingDownParams.bShouldActivateCapability)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FKeepIceKingDownActivationParams Params)
	{
		FButtonMashSettings Settings;
		Settings.ProgressionMode = EButtonMashProgressionMode::MashRateOnly;
		Settings.WidgetAttachComponent = Params.Boss.OrbImpactFX;
		Settings.bBlockOtherGameplay = false;
		Game::Zoe.StartButtonMash(Settings, this);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		Game::Zoe.StopButtonMash(this);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if(!Player.HasControl())
			return;

		float MashRate;
		bool bIsMashRateSufficient;
		Game::Zoe.GetButtonMashCurrentRate(this, MashRate, bIsMashRateSufficient);	

		if(bIsMashRateSufficient && !Comp.bIsMashingSufficient)
		{
			CrumbMashingSufficient(true);
		}
		else if(!bIsMashRateSufficient && Comp.bIsMashingSufficient)
		{
			CrumbMashingSufficient(false);
		}
			
		float LeftFF = 0.0;
		float RightFF = 0.5;
		Game::Zoe.SetFrameForceFeedback(LeftFF, RightFF, 0.0, 0.0);
	}

	UFUNCTION(CrumbFunction)
	void CrumbMashingSufficient(bool bMashingSufficient)
	{
		Comp.bIsMashingSufficient = bMashingSufficient;
	}
};