class UAnimInstanceDarkMioPostProcess : UAnimInstance
{

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bIsControlledByCutscene;

	UPROPERTY(Transient, BlueprintReadOnly, NotEditable)
	bool bEnableLegCableCollision;

	AHazeActor HazeOwningActor;

	APrisonBoss Boss;

	UFUNCTION(BlueprintOverride)
	void BlueprintBeginPlay()
	{
		HazeOwningActor = Cast<AHazeActor>(OwningComponent.GetOwner());
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintInitializeAnimation()
	{
		Boss = Cast<APrisonBoss>(HazeOwningActor);
	}

	UFUNCTION(BlueprintOverride)
	void BlueprintUpdateAnimation(float DeltaTime)
	{
		if (Boss == nullptr)
			return;

		bIsControlledByCutscene = HazeOwningActor.bIsControlledByCutscene;
		bEnableLegCableCollision = Boss.bAnimLegCablePhysicsCollision;
	}
}