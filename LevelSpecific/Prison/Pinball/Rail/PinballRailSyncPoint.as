enum EPinballRailSyncPointMode
{
	// Stop whenever the player travels through this sync point
	Always,

	// Stop if we are the entry to the spline, meaning that the player starts going through the spline after us. Can be either the Head or Tail
	OnEnter,

	// Stop if we are the exit of the spline, meaning that the player stops being in the spline after us. Can be either Head or Tail
	OnExit,

	// Completely disables this sync point
	Never,
};

UCLASS(NotBlueprintable, HideCategories = "Rendering Debug Activation Cooking Tags LOD Navigation")
class UPinballRailSyncPoint : USceneComponent
{
	default PrimaryComponentTick.bStartWithTickEnabled = false;

	access Internal = private, APinballRail, FPinballRailMoveSimulation;

	UPROPERTY(EditInstanceOnly)
	EPinballRailSyncPointMode Mode = EPinballRailSyncPointMode::OnEnter;

	UPROPERTY(EditInstanceOnly)
	private float EnterSpeed = 1000;

	access:Internal
	EPinballRailHeadOrTail SyncPointSide;

	private UStaticMeshComponent MeshComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if(GetNumChildrenComponents() == 1)
		{
			MeshComp = Cast<UStaticMeshComponent>(GetChildComponent(0));
			if(MeshComp != nullptr)
				SetComponentTickEnabled(true);
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		const float Alpha = (Time::GameTimeSeconds % 10) / 10;
		MeshComp.SetRelativeRotation(FRotator(90, 0, 360 * Alpha));
	}

	access:Internal
	void UpdateVisibility(bool bTwoSided)
	{
		if(!bTwoSided)
		{
			// Some modes are incompatible with Two Sided, so we must change them.
			if(SyncPointSide == EPinballRailHeadOrTail::Head)
			{
				switch(Mode)
				{
					case EPinballRailSyncPointMode::OnExit:
						Mode = EPinballRailSyncPointMode::Never;
						break;

					default:
						break;
				}
			}
			else
			{
				switch(Mode)
				{
					case EPinballRailSyncPointMode::Always:
						Mode = EPinballRailSyncPointMode::OnExit;
						break;

					case EPinballRailSyncPointMode::OnEnter:
						Mode = EPinballRailSyncPointMode::Never;
						break;

					default:
						break;
				}
			}
		}

		switch(Mode)
		{
			case EPinballRailSyncPointMode::Always:
			case EPinballRailSyncPointMode::OnEnter:
			case EPinballRailSyncPointMode::OnExit:
			{
				SetVisibility(true, true);
				break;
			}

			case EPinballRailSyncPointMode::Never:
			{
				SetVisibility(false, true);
				break;
			}
		}
	}

	access:Internal
	bool ShouldSync(EPinballRailEnterOrExit EnterOrExit) const
	{
		switch(Mode)
		{
			case EPinballRailSyncPointMode::Always:
				return true;

			case EPinballRailSyncPointMode::OnEnter:
				return EnterOrExit == EPinballRailEnterOrExit::Enter;

			case EPinballRailSyncPointMode::OnExit:
				return EnterOrExit == EPinballRailEnterOrExit::Exit;

			case EPinballRailSyncPointMode::Never:
				return false;
		}
	}

	float GetEnterRailSpeed() const
	{
		if(SyncPointSide == EPinballRailHeadOrTail::Head)
			return EnterSpeed;
		else
			return -EnterSpeed;
	}

	UFUNCTION(BlueprintPure)
	FVector GetLaunchDirection(EPinballRailEnterOrExit EnterOrExit) const
	{
		if(SyncPointSide == EPinballRailHeadOrTail::Head)
		{
			if(EnterOrExit == EPinballRailEnterOrExit::Enter)
				return UpVector;
			else
				return -UpVector;
		}
		else
		{
			if(EnterOrExit == EPinballRailEnterOrExit::Exit)
				return UpVector;
			else
				return -UpVector;
		}
	}

#if EDITOR
	FString GetModeString() const
	{
		switch(Mode)
		{
			case EPinballRailSyncPointMode::Always:
				return "Always";

			case EPinballRailSyncPointMode::OnEnter:
				return "OnEnter";

			case EPinballRailSyncPointMode::OnExit:
				return "OnExit";

			case EPinballRailSyncPointMode::Never:
				return "Never";
		}
	}
#endif
};