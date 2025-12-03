class ASanctuaryCentipedeConsumableWater : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent, Attach = Root)
	UCentipedeBiteResponseComponent BiteResponseComp;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent CentipedeStomachMeshComp;
	default CentipedeStomachMeshComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	default CentipedeStomachMeshComp.SetHiddenInGame(true);

	UPROPERTY(DefaultComponent, Attach = Root)
	USceneComponent SprayPivotComp;

	UPROPERTY(DefaultComponent, Attach = SprayPivotComp)
	UNiagaraComponent VFXComp;

	UPROPERTY(DefaultComponent, Attach = SprayPivotComp)
	UHazeCapsuleCollisionComponent SprayCollisionComp;

	UPROPERTY(Category = TimeLikes)
	FHazeTimeLike FoodTravelTimeLike;

	FVector Direction;

	AHazePlayerCharacter EatPlayer;
	AHazePlayerCharacter ShootPlayer;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorTickEnabled(false);
		BiteResponseComp.OnCentipedeBiteStarted.AddUFunction(this, n"HandleBiteStarted");
		BiteResponseComp.OnCentipedeBiteStopped.AddUFunction(this, n"HandleBiteStopped");
		FoodTravelTimeLike.BindUpdate(this, n"FoodTravelUpdate");
		FoodTravelTimeLike.BindFinished(this, n"FoodTravelFinished");
		VFXComp.Deactivate();

		SprayCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION()
	private void HandleBiteStarted(FCentipedeBiteEventParams BiteParams)
	{
		EatPlayer = BiteParams.Player;
		ShootPlayer = BiteParams.Player.OtherPlayer;

		StartWater();
	}

	UFUNCTION()
	private void HandleBiteStopped(FCentipedeBiteEventParams BiteParams)
	{
		StopWater();
	}

	UFUNCTION()
	private void FoodTravelUpdate(float Alpha)
	{
		UPlayerCentipedeComponent CentipedeComponent = UPlayerCentipedeComponent::Get(EatPlayer);
		FVector Location = CentipedeComponent.GetLocationAtBodyFraction(Alpha * 0.9 + 0.1) + FVector::UpVector * 20.0;
		CentipedeStomachMeshComp.SetWorldLocation(Location);
	}

	UFUNCTION()
	private void FoodTravelFinished()
	{
		Direction = ShootPlayer.ActorForwardVector;
		VFXComp.Activate();
		SetActorTickEnabled(true);
		CentipedeStomachMeshComp.SetHiddenInGame(true);
	}

	UFUNCTION()
	private void StartWater()
	{
		Direction = ShootPlayer.ActorForwardVector;
		VFXComp.Activate();
		SetActorTickEnabled(true);
		
		SprayCollisionComp.SetCollisionEnabled(ECollisionEnabled::QueryAndPhysics);
	}

	UFUNCTION()
	private void StopWater()
	{
		SetActorTickEnabled(false);
		VFXComp.Deactivate();
		SprayCollisionComp.SetCollisionEnabled(ECollisionEnabled::NoCollision);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		UPlayerCentipedeComponent PlayerCentipedeComponent = UPlayerCentipedeComponent::Get(ShootPlayer);
		FTransform CentipedeHeadTransform = PlayerCentipedeComponent.GetMeshHeadTransform();

		SprayPivotComp.SetWorldLocationAndRotation(CentipedeHeadTransform.Translation, CentipedeHeadTransform.Rotation);
	}
};