class ACoastTrainSpinnerInnerPlatform : AHazeActor
{
	UPROPERTY(DefaultComponent)
	UHazeCrumbSyncedFloatComponent SyncedFloat;
	
	private UStaticMeshComponent MeshComp;
	
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		SetActorControlSide(Game::Zoe);
		MeshComp = UStaticMeshComponent::Get(this, n"StaticMesh"); 
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaTime)
	{
		
		if(HasControl())
		{
			MeshComp.AddLocalRotation(FRotator(0.0, 0.0, 40.0 * DeltaTime));
			FRotator Rotation = MeshComp.GetRelativeRotation();
			SyncedFloat.Value = Rotation.Roll;
		}
		else
		{	
			FRotator Rotation = MeshComp.GetRelativeRotation();			
			Rotation.Roll = SyncedFloat.Value;
			MeshComp.SetRelativeRotation(Rotation);
		}
	}
};
