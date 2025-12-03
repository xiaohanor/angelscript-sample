UCLASS(Abstract)
class AIslandTowerTeleport : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	UPROPERTY(DefaultComponent)
	UHazeCapsuleCollisionComponent Collision;
	
	UPROPERTY(EditInstanceOnly)
	AIslandTowerTeleport TeleportSibling;

	UPROPERTY(EditAnywhere)
	EHazePlayer UsableByPlayer;
	default UsableByPlayer = EHazePlayer::Mio;

	UPROPERTY(EditAnywhere)
	bool bUsePlayerRotation;

	UPROPERTY()
	UMaterialInterface MioMaterial;

	UPROPERTY()
	UMaterialInterface ZoeMaterial;

	FVector SiblingLocation;
	bool bOnCoolDown;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (TeleportSibling == nullptr)
			return;

		Collision.OnComponentBeginOverlap.AddUFunction(this, n"OnOverlap");
		Collision.OnComponentEndOverlap.AddUFunction(this, n"OnEndOverlap");
		SiblingLocation = TeleportSibling.GetActorLocation();
	}

	UFUNCTION()
	private void OnOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex, bool bFromSweep,
	                       const FHitResult&in SweepResult)
	{	
		if (TeleportSibling == nullptr)
			return;

		if (bOnCoolDown)
			return;


		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			if (Player != Game::GetPlayer(EHazePlayer::Mio)) 
				return;
		}

		if(UsableByPlayer == EHazePlayer::Zoe)
		{
			if (Player != Game::GetPlayer(EHazePlayer::Zoe)) 
				return;
		}

		bOnCoolDown = true;
		TeleportSibling.bOnCoolDown = true;

		if (bUsePlayerRotation)
			Player.TeleportActor(SiblingLocation,Player.GetActorRotation(), this, true);
		else
			Player.TeleportActor(SiblingLocation, TeleportSibling.GetActorRotation(), this, true);

		// FVector Impulse = Trajectory::CalculateVelocityForPathWithHeight(Player.ActorLocation, GetActorLocation(), 100, 1000, 0);
		// Player.AddMovementImpulse(Impulse);

		Player.AddMovementImpulse((TeleportSibling.GetActorForwardVector() * 1000));

		BP_FlashMesh();
		TeleportSibling.BP_FlashMesh();

	}

	UFUNCTION()
	private void OnEndOverlap(UPrimitiveComponent OverlappedComponent, AActor OtherActor,
	                       UPrimitiveComponent OtherComp, int OtherBodyIndex)
	{	

		if (TeleportSibling == nullptr)
			return;

		auto Player = Cast<AHazePlayerCharacter>(OtherActor);
		if (Player == nullptr)
			return;

		if(UsableByPlayer == EHazePlayer::Mio)
		{
			if (Player != Game::GetPlayer(EHazePlayer::Mio)) 
				return;
		}

		if(UsableByPlayer == EHazePlayer::Zoe)
		{
			if (Player != Game::GetPlayer(EHazePlayer::Zoe)) 
				return;
		}

		bOnCoolDown = false;
		

	}

	UFUNCTION(BlueprintEvent)
	void BP_FlashMesh() {}

};
