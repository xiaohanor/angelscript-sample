class UTundraFishieCollisionHandlerComponent : USceneComponent
{
	default PrimaryComponentTick.TickInterval = 2.0;

	// Currently block fishies above this component but let them through from below
	UPROPERTY(EditInstanceOnly)
	AHazeActor Fishie;

	UPROPERTY(EditInstanceOnly)
	float Thickness = 140.0;

	UStaticMeshComponent Mesh;
	bool bBlocked = true;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Mesh = UStaticMeshComponent::Get(Owner);	
		if (ensure(Mesh != nullptr))
			Mesh.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);		
		bBlocked = true;
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		if (!IsValid(Fishie) || (Mesh == nullptr))
			return;

		if (bBlocked && (Fishie.ActorLocation.Z < WorldLocation.Z))
		{
			Mesh.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Ignore);		
			bBlocked = false;
		}
		else if (!bBlocked && (Fishie.ActorLocation.Z > WorldLocation.Z + Thickness))
		{
			Mesh.SetCollisionResponseToChannel(ECollisionChannel::EnemyCharacter, ECollisionResponse::ECR_Block);		
			bBlocked = true;
		}

		// No need to tick very often
		if (Game::Mio.ActorLocation.IsWithinDist(Owner.ActorLocation, 5000.0))
			SetComponentTickInterval(0.2);
		else 		
			SetComponentTickInterval(2.0);
	}

#if EDITOR
	UFUNCTION(BlueprintOverride)
	void OnVisualizeInEditor() const
	{
		Debug::DrawDebugSolidPlane(WorldLocation + UpVector * Thickness, UpVector, 200.0, 200.0, FLinearColor::LucBlue);	
		Debug::DrawDebugSolidPlane(WorldLocation, UpVector, 200.0, 200.0, FLinearColor::Green);	
	}
#endif
};