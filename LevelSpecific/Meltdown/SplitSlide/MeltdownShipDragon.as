class AMeltdownShipDragon : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent ShipRoot;
	FVector ShipLocation;
	FRotator ShipRotation;

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent DragonRoot;
	FVector DragonLocation;
	FRotator DragonRotation;

	UPROPERTY(DefaultComponent, Attach = DragonRoot)
	UNiagaraComponent FireVFXComp;

	UPROPERTY()
	FHazeTimeLike MoveAcrossScreenTimeLike;
	default MoveAcrossScreenTimeLike.UseSmoothCurveZeroToOne();
	default MoveAcrossScreenTimeLike.Duration = 3.0;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		MoveAcrossScreenTimeLike.BindUpdate(this, n"MoveAcrossScreenTimeLikeUpdate");
		MoveAcrossScreenTimeLike.BindFinished(this, n"MoveAcrossScreenTimeLikeFinished");
		ShipLocation = ShipRoot.WorldLocation;
		ShipRotation = ShipRoot.WorldRotation;
		DragonLocation = DragonRoot.WorldLocation;
		DragonRotation = DragonRoot.WorldRotation;
		DragonRoot.SetWorldLocation(ShipLocation + FVector::ForwardVector * -500000);
		AddActorDisable(this);
	}

	UFUNCTION()
	void MoveAcrossScreen()
	{
		RemoveActorDisable(this);
		MoveAcrossScreenTimeLike.Play();
	}

	UFUNCTION()
	private void MoveAcrossScreenTimeLikeUpdate(float CurrentValue)
	{
		FRotator Rotation = Math::LerpShortestPath(ShipRotation, DragonRotation, CurrentValue);
		FVector Location = Math::Lerp(ShipLocation, DragonLocation, CurrentValue);
		ShipRoot.SetWorldLocationAndRotation(Location, Rotation);
		DragonRoot.SetWorldLocationAndRotation(Location + FVector::ForwardVector * -500000.0, Rotation);
	}

	UFUNCTION()
	private void MoveAcrossScreenTimeLikeFinished()
	{
		FireVFXComp.Activate();
	}
};