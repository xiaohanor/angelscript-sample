class USummitKnightSwordComponent : UStaticMeshComponent
{
	AHazeActor HazeOwner;

	bool bShattered;
	float bShatteredTime;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		HazeOwner = Cast<AHazeActor>(Owner);
		// InternalShatter();
	}

	FCollisionShape GetCollisionShape()
	{
		FCollisionShape SwordShape;
		SwordShape.SetCapsule(250, 650);
		return SwordShape;
	}

	FTransform GetTransform()
	{
		FTransform SwordTransform = WorldTransform;
		SwordTransform.Rotation = (RightVector.Rotation() + FRotator(90, 0, 0)).Quaternion();
		SwordTransform.AddToTranslation(SwordTransform.Rotation.UpVector * 400);
		return SwordTransform;
	}

	private void InternalShatter()
	{
		AddComponentVisualsBlocker(this);
		bShattered = true;
		bShatteredTime = Time::GetGameTimeSeconds();
	}

	void Shatter()
	{
	}

	void Reform()
	{
		RemoveComponentVisualsBlocker(this);
		bShattered = false;
	}
}