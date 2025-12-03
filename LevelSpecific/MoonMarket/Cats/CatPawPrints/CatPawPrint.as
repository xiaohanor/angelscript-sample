class ACatPawPrint : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent Root;

	// UPROPERTY(DefaultComponent, Attach = Root)
	// UDecalComponent Decal;

	UPROPERTY(EditAnywhere)
	bool bDebugDraw;

	float AlphaAlongSpline;

	UPROPERTY(DefaultComponent, Attach = Root)
	UStaticMeshComponent TempMesh;
	default TempMesh.SetCollisionEnabled(ECollisionEnabled::NoCollision);

	bool bIsInvisible;
	bool bPermaInvisible;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AddActorVisualsBlock(this);
		bIsInvisible = true;
		SetActorTickEnabled(false);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		// if (!bIsInvisible)
		// 	Debug::DrawDebugSphere(ActorLocation, 50.0, 12, FLinearColor::LucBlue, 5.0);
		// else	
		// 	Debug::DrawDebugSphere(ActorLocation, 50.0, 12, FLinearColor::Red, 5.0);
	}

	void SetPawVisible(bool bVisible)
	{
		if (bPermaInvisible)
			return;
		
		if (!bVisible && !bIsInvisible)
		{
			AddActorVisualsBlock(this);
			bIsInvisible = true;
		}
		else if (bVisible && bIsInvisible)
		{
			RemoveActorVisualsBlock(this);
			bIsInvisible = false;
		}
	}

	void SetPawPermaInvisible()
	{
		AddActorVisualsBlock(this);
		bPermaInvisible = true;
	}
};