event void FIslandBigZombieAttackResponseSignature(AHazeCharacter ImpactInstigator);

class UIslandBigZombieAttackResponseComponent : USceneComponent
{
	UPROPERTY(Category = "Impact")
	FIslandBigZombieAttackResponseSignature OnImpact;

	UPrimitiveComponent PrimitiveShape;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		PrimitiveShape = UPrimitiveComponent::Get(Owner);
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.JoinTeam(n"BigZombieAttackTarget");
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.LeaveTeam(n"BigZombieAttackTarget");
	}

	bool GetActivationShapeAndLocation(FCollisionShape& OutShape, FTransform& OutTransform) const
	{
		if(PrimitiveShape != nullptr)
		{
			OutTransform = PrimitiveShape.GetWorldTransform();
			OutShape = PrimitiveShape.GetCollisionShape();
			return true;
		}

		return false;
	}
}