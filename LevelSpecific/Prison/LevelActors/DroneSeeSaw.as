class ADroneSeeSaw : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	UFauxPhysicsAxisRotateComponent AxisRotateComp;
	default AxisRotateComp.NetworkMode = EFauxPhysicsAxisRotateNetworkMode::TwoWaySynced;

	UPROPERTY(DefaultComponent, Attach = AxisRotateComp)
	UStaticMeshComponent MeshComp;

	UPROPERTY(DefaultComponent)
	UMovementImpactCallbackComponent ImpactComp;

	UPROPERTY(DefaultComponent)
	UDroneMagneticSurfaceComponent MagnetSurfaceComp;

	UPROPERTY(DefaultComponent)
	UDisableComponent DisableComp;
	default DisableComp.bAutoDisable = true;

#if EDITOR
	UPROPERTY(DefaultComponent)
	UTemporalLogTransformLoggerComponent TransformLoggerComp;
#endif

	UPROPERTY(EditAnywhere)
	float SpringStrengthOverride;

	UPROPERTY(EditAnywhere)
	float HitImpulseStrength = -3;

	AHazePlayerCharacter MagnetDronePlayer;
	AHazePlayerCharacter SwarmDronePlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		ImpactComp.OnGroundImpactedByPlayer.AddUFunction(this, n"ImpactPlayer");
		ImpactComp.OnGroundImpactedByPlayerEnded.AddUFunction(this, n"ImpactPlayerEnded");

		MagnetSurfaceComp.OnMagnetDroneAttached.AddUFunction(this, n"ImpactMagnet");
		MagnetSurfaceComp.OnMagnetDroneDetached.AddUFunction(this, n"ImpactMagnetEnded");
	}		

	UFUNCTION()
	private void ImpactMagnet(FOnMagnetDroneAttachedParams Params)
	{
		MagnetDronePlayer = Drone::GetMagnetDronePlayer();
	}

	UFUNCTION()
	private void ImpactMagnetEnded(FOnMagnetDroneDetachedParams Params)
	{
		MagnetDronePlayer = nullptr;
	}

	UFUNCTION()
	private void ImpactPlayer(AHazePlayerCharacter Player)
	{
		if(Player == Drone::GetMagnetDronePlayer())
		{
			MagnetDronePlayer = Player;
			AxisRotateComp.ApplyImpulse(MagnetDronePlayer.GetActorLocation(), FVector::UpVector * (HitImpulseStrength + 0.5));
		}
		else
		{
			SwarmDronePlayer = Player;
			AxisRotateComp.ApplyImpulse(SwarmDronePlayer.GetActorLocation(), FVector::UpVector * HitImpulseStrength);
		}
	}

	UFUNCTION()
	private void ImpactPlayerEnded(AHazePlayerCharacter Player)
	{
		if (Player == Drone::GetMagnetDronePlayer())
			MagnetDronePlayer = nullptr;
		else
			SwarmDronePlayer = nullptr;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{	
		if (IsValid(MagnetDronePlayer))
			AxisRotateComp.ApplyForce(MagnetDronePlayer.GetActorLocation(),  FVector::UpVector * -12);

		if (IsValid(SwarmDronePlayer))
			AxisRotateComp.ApplyForce(SwarmDronePlayer.GetActorLocation(), FVector::UpVector * -10.0);

		if (MagnetDronePlayer == nullptr && SwarmDronePlayer == nullptr)
			AxisRotateComp.SpringStrength = SpringStrengthOverride;
		else
			AxisRotateComp.SpringStrength = 0.0;
	}
}