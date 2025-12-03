
UFUNCTION()
ABaseFieldSystemActor SpawnFieldSystemOnActor( TSubclassOf<ABaseFieldSystemActor> FieldSystemClass, AActor InActor)
{
	if(InActor == nullptr)
		return nullptr;

	if(!FieldSystemClass.IsValid())
		return nullptr;

	UObject SpawnedObject = SpawnActor(
		FieldSystemClass.Get(),
		InActor.GetActorLocation()
	);

	ABaseFieldSystemActor FieldSystemActor = Cast<ABaseFieldSystemActor>(SpawnedObject);

	FieldSystemActor.AttachToActor(InActor, NAME_None, EAttachmentRule::SnapToTarget);

	return FieldSystemActor;
}

UFUNCTION()
ABaseFieldSystemActor SpawnFieldSystemOnComponent(
	TSubclassOf<ABaseFieldSystemActor> FieldSystemClass, 
	UPrimitiveComponent InComp,
	FName InSocketName = NAME_None
)
{
	if(InComp == nullptr)
		return nullptr;

	if(!FieldSystemClass.IsValid())
		return nullptr;

	FTransform TargetSocket = InComp.GetSocketTransform(InSocketName);

	UObject SpawnedObject = SpawnActor(
		FieldSystemClass.Get(),
		TargetSocket.GetLocation()
	);

	ABaseFieldSystemActor FieldSystemActor = Cast<ABaseFieldSystemActor>(SpawnedObject);

	FieldSystemActor.AttachToComponent(InComp, InSocketName, EAttachmentRule::SnapToTarget);

	return FieldSystemActor;
}

UFUNCTION()
ABaseFieldSystemActor SpawnFieldSystemAtLocation(TSubclassOf<ABaseFieldSystemActor> FieldSystemClass, FVector InLocation, FRotator InRotator = FRotator::ZeroRotator)
{
	UObject SpawnedObject = SpawnActor(
		FieldSystemClass.Get(),
		InLocation,
		InRotator
	);

	ABaseFieldSystemActor FieldSystemActor = Cast<ABaseFieldSystemActor>(SpawnedObject);

	return FieldSystemActor;
}

UFUNCTION()
ABaseImpactFieldSystemActor SpawnImpactField(
	const FVector InLocation, 
	const FRotator InRotation,
	const float InStrainMagnitude = 1000000.0,
	const float InForceMagnitude = 6000.0,
	const float InTorqueMagnitude = 3000.0,
	const float InRadius = 200.0
)
{
	ABaseImpactFieldSystemActor SpawnedField = SpawnActor(
		AExampleImpactFieldSystemActor,
		InLocation,
		InRotation,
		bDeferredSpawn = true);

	SpawnedField.StrainMagnitude = InStrainMagnitude;
	SpawnedField.ForceMagnitude = InForceMagnitude;
	SpawnedField.TorqueMagnitude = InTorqueMagnitude;
	SpawnedField.SphereCollision.SetSphereRadius(InRadius);

	FinishSpawningActor(SpawnedField);

	return SpawnedField;
}