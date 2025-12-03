struct FSketchbookMountGoatActivateParams
{
	ASketchbookGoat Goat;
};

class USketchbookMountGoatPlayerCapability : UHazePlayerCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;

	default TickGroup = EHazeTickGroup::BeforeGameplay;

	USketchbookGoatPlayerComponent PlayerComp;
	UPlayerMovementComponent MoveComp;

	ASketchbookGoat GoatToMount;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		PlayerComp = USketchbookGoatPlayerComponent::Get(Player);
		MoveComp = UPlayerMovementComponent::Get(Player);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate(FSketchbookMountGoatActivateParams& Params) const
	{
		if(!MoveComp.HasAnyValidBlockingImpacts())
			return false;

		ASketchbookGoat Goat;
		for(auto Impact : MoveComp.AllImpacts)
		{
			Goat = Cast<ASketchbookGoat>(Impact.Actor);
			if(Goat != nullptr)
				break;
		}

		if(Goat == nullptr)
			return false;

		if(Goat.CopyStencilDepthFrom != Player.Player)
			return false;

		if(Goat.bHasEverBeenMounted)
			return false;

		Params.Goat = Goat;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if(GoatToMount == nullptr)
			return true;

		if(GoatToMount.MountedPlayer == Player.OtherPlayer)
			return true;

		return false;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated(FSketchbookMountGoatActivateParams Params)
	{
		GoatToMount = Params.Goat;
		GoatToMount.Mount(PlayerComp);
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
	}
};