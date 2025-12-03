
UCLASS(Abstract)
class UWorld_Tundra_MonkeyRealm_Platform_FloatingIce_SoundDef : USoundDefBase
{
	/* AUTO-GENERATED CODE - Anything from here to end should NOT be edited! */

	UFUNCTION(BlueprintEvent)
	void BreachWater(){}

	UFUNCTION(BlueprintEvent)
	void OnRopeDetached(){}

	/* END OF AUTO-GENERATED CODE */

	UFauxPhysicsConeRotateComponent FuaxRotation;
	UStaticMeshComponent IceMesh;

	const float MAX_ROTATION_DELTA = 0.3;
	const float MAX_ROTATION_ANGLE = 0.001;

	UPROPERTY(BlueprintReadOnly)
	float RotationDelta;

	UPROPERTY(BlueprintReadOnly)
	float AbsRotation;

	FRotator PreviousRotation;

	ATundra_River_FloatingIce Ice;

	UFUNCTION(BlueprintOverride)
	void ParentSetup()
	{
		FuaxRotation = UFauxPhysicsConeRotateComponent::Get(HazeOwner);
		IceMesh = UStaticMeshComponent::Get(HazeOwner);
		Ice = Cast<ATundra_River_FloatingIce>(HazeOwner);
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaSeconds)
	{
		const FRotator Rotation = DefaultEmitter.AudioComponent.GetWorldRotation();
		const float RotationAmt = Rotation.Quaternion().AngularDistance(PreviousRotation.Quaternion());
		const float Delta = RotationAmt / DeltaSeconds;

		const float RotationDot = 1 - Rotation.UpVector.DotProduct(FVector::UpVector);	
		AbsRotation = Math::GetMappedRangeValueClamped(FVector2D(0.0, MAX_ROTATION_ANGLE), FVector2D(0.0, 1.0), RotationDot);	
		
		RotationDelta = Math::GetMappedRangeValueClamped(FVector2D(-MAX_ROTATION_DELTA, MAX_ROTATION_DELTA), FVector2D(-1.0, 1.0), Delta);

		PreviousRotation = Rotation;
	}	

	UFUNCTION(BlueprintPure)
	bool IsAttachedToBottom()
	{	
		return !Ice.CheckIfAllRopesAreUntethered();
	}
}