class ASummitTeenDragonRollLauncher : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent LeftRopeRoot;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent RightRopeRoot;

	UPROPERTY(DefaultComponent, Attach = LeftRopeRoot)
	UHazeTEMPCableComponent LeftCable;

	UPROPERTY(DefaultComponent, Attach = RightRopeRoot)
	UHazeTEMPCableComponent RightCable;

	UPROPERTY(DefaultComponent, Attach = Root, ShowOnActor)
	UFauxPhysicsTranslateComponent PullRoot;
	default PullRoot.bConstrainY = true;
	default PullRoot.bConstrainZ = true;
	default PullRoot.bConstrainX = true;
	default PullRoot.MinX = -500.0;
	default PullRoot.Friction = 5.0;
	default PullRoot.SpringStrength = 50.0;

	UPROPERTY(DefaultComponent, Attach = PullRoot)
	UInteractionComponent InteractionComp;
	default InteractionComp.UsableByPlayers = EHazeSelectPlayer::Zoe;
	default InteractionComp.InteractionCapability = n"SummitTeenDragonRollLauncherDragCapability";

	/** Camera to use while pulling back the launcher
	 * (Does not need to be set) */
	UPROPERTY(EditAnywhere, Category = "Settings")
	AHazeCameraActor Camera;

	/** How fast the launcher is pulled back with input */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float PullBackSpeed = 500.0;

	/** How fast the launcher is pulled forward with input */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float PullForwardSpeed = 500.0;

	/** How much resistance is applied while pulling
	 * Time axle : How much percentage is pulled 0 -> 1
	 * Value axle : How much precentage resistance is applied 0 -> 1 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	FRuntimeFloatCurve PullBackResistanceCurve;
	default PullBackResistanceCurve.AddDefaultKey(0.0, 0.0);
	default PullBackResistanceCurve.AddDefaultKey(0.5, 0.0);
	default PullBackResistanceCurve.AddDefaultKey(1.0, 0.9);

	/** The maximum speed forwards gained from launching with the launcher
	 * Based on how far back it is pulled (Percent of Max)
	 */
	UPROPERTY(EditAnywhere, Category = "Settings")
	float MaxLaunchSpeed = 12000.0;

	private FVector OriginalPullRootOffset;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		LeftCable.SetAttachEndTo(this, n"PullRoot");
		RightCable.SetAttachEndTo(this, n"PullRoot");

		OriginalPullRootOffset = PullRoot.RelativeLocation;
	}
	void Move(float MoveDelta)
	{
		float PullAlpha = GetPullAlpha();
		float PullBackResistance = PullBackResistanceCurve.GetFloatValue(PullAlpha);
		float PullMultiplier = MoveDelta > 0
			? 1.0 - PullBackResistance
			: 1.0;
		float ResistedMoveDelta = MoveDelta * PullMultiplier;
		FVector NewPos = PullRoot.RelativeLocation;
		NewPos.X = Math::Clamp(NewPos.X - ResistedMoveDelta, OriginalPullRootOffset.X + PullRoot.MinX, OriginalPullRootOffset.X + PullRoot.MaxX);
		PullRoot.SetRelativeLocation(NewPos);
	}

	float GetPullAlpha() const
	{
		return PullRoot.RelativeLocation.X / (OriginalPullRootOffset.X + PullRoot.MinX);
	}

	void StartPulling()
	{
		PullRoot.AddDisabler(this);
	}

	void StopPulling()
	{
		PullRoot.RemoveDisabler(this);
	}
};