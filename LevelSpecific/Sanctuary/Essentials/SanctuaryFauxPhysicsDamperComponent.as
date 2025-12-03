class USanctuaryFauxPhysicsDamperComponent : USceneComponent
{
	UPROPERTY(EditAnywhere)
	FVector TranslationMinDampingLength = FVector::UpVector * 100.0;

	UPROPERTY(EditAnywhere)
	FVector TranslationMaxDampingLength = FVector::UpVector * 100.0;

	UPROPERTY(EditAnywhere)
	FVector TranslationMinDampingStrength = FVector::UpVector * 1.0;

	UPROPERTY(EditAnywhere)
	FVector TranslationMaxDampingStrength = FVector::UpVector * 1.0;

	UPROPERTY(EditAnywhere)
	FVector2D RotationDampingAngle;

	UPROPERTY(EditAnywhere)
	FVector2D RotationDampingStrength;

	UFauxPhysicsTranslateComponent TranslateComp;
	UFauxPhysicsAxisRotateComponent AxisRotateComp;

	TArray<UFauxPhysicsForceComponent> ForceComps;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		TranslateComp = Cast<UFauxPhysicsTranslateComponent>(AttachParent);
		AxisRotateComp = Cast<UFauxPhysicsAxisRotateComponent>(AttachParent);
	
		AttachParent.GetChildrenComponentsByClass(UFauxPhysicsForceComponent, true, ForceComps);
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{
		FVector Force;
		for (auto ForceComp : ForceComps)
			Force += ForceComp.Force;

		if (TranslateComp != nullptr)
		{
			FVector RelativeVelocity = TranslateComp.WorldTransform.InverseTransformVectorNoScale(TranslateComp.GetVelocity());

			PrintToScreen("Speed: " + RelativeVelocity, 0.0, FLinearColor::Green);
			PrintToScreen("Force: " + Force, 0.0, FLinearColor::Green);

			if (RelativeVelocity.Z > 0.0 && TranslateComp.RelativeLocation.Z > TranslateComp.MaxZ - TranslationMaxDampingLength.Z)
			{
				float Scale = Math::NormalizeToRange(TranslateComp.RelativeLocation.Z, TranslateComp.MaxZ - TranslationMaxDampingLength.Z, TranslateComp.MaxZ);
				PrintToScreen("DampMax" + Scale, 0.0, FLinearColor::Green);
				TranslateComp.ApplyForce(TranslateComp.WorldLocation, -FVector::UpVector * TranslationMaxDampingStrength.Z * (TranslateComp.Friction * 2.0) * (1000.0 / TranslationMaxDampingLength.Z) * Math::Abs(RelativeVelocity.Z));
				TranslateComp.ApplyForce(TranslateComp.WorldLocation, -FVector::UpVector * Scale * Math::Max(0.0, Force.Z));
			}

			if (RelativeVelocity.Z < 0.0 && TranslateComp.RelativeLocation.Z < TranslateComp.MinZ + TranslationMinDampingLength.Z)
			{
				float Scale = 1.0 - Math::NormalizeToRange(TranslateComp.RelativeLocation.Z, TranslateComp.MinZ + TranslationMinDampingLength.Z, TranslateComp.MinZ);
				PrintToScreen("DampMin" + Scale, 0.0, FLinearColor::Green);
				TranslateComp.ApplyForce(TranslateComp.WorldLocation, FVector::UpVector * TranslationMinDampingStrength.Z * (TranslateComp.Friction * 2.0) * (1000.0 / TranslationMinDampingLength.Z) * Math::Abs(RelativeVelocity.Z));
				TranslateComp.ApplyForce(TranslateComp.WorldLocation, -FVector::UpVector * Scale * Math::Min(0.0, Force.Z));
			}
/*
			if (RelativeVelocity.Z < 0.0 && TranslateComp.RelativeLocation.Z < TranslateComp.MinZ + TranslationMinDampingLength.Z)
			{
				float Scale = 1.0 - Math::NormalizeToRange(TranslateComp.RelativeLocation.Z, TranslateComp.MinZ + TranslationMinDampingLength.Z, TranslateComp.MinZ);
				PrintToScreen("DampMin" + Scale, 0.0, FLinearColor::Green);
				TranslateComp.ApplyForce(TranslateComp.WorldLocation, FVector::UpVector * Scale * Scale * TranslationMinDampingStrength.Z * (1000.0 / TranslationMinDampingLength.Z) * 10.0 * Math::Abs(RelativeVelocity.Z));
			}
*/
		}

		if (AxisRotateComp != nullptr)
		{
			
		}
	}
};