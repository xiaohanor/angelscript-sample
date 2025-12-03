class AVillageElevatorBoulder : AHazeActor
{
	UPROPERTY(DefaultComponent, RootComponent)
	USceneComponent RootComp;

	UPROPERTY(DefaultComponent, Attach = RootComp)
	USceneComponent BoulderRoot;

	UPROPERTY(EditDefaultsOnly)
	FHazeTimeLike DropTimeLike;

	bool bDropped = false;
	FVector DropStartLoc;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		DropTimeLike.BindUpdate(this, n"UpdateDrop");
	}

	UFUNCTION()
	void Drop()
	{
		DropStartLoc = ActorLocation;
		DropTimeLike.PlayFromStart();
	}

	UFUNCTION()
	private void UpdateDrop(float CurValue)
	{
		FVector Loc = Math::Lerp(DropStartLoc, DropStartLoc - (FVector::UpVector * 4500.0), CurValue);
		SetActorLocation(Loc);
	}
}