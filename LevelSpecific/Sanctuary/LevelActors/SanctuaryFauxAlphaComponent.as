enum EAlphaFromContraints
{
	Rotation,
	TranslationX,
	TranslationY,
	TranslationZ
}

class USanctuaryFauxAlphaComponent : UActorComponent
{
	UPROPERTY(EditAnywhere)
	AActor FauxPhysicsOwner;

	UPROPERTY(EditAnywhere)
	EAlphaFromContraints AlphaFromAxis;

	UPROPERTY(EditAnywhere)
	bool bUseFauxPhysicsContraints = true;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "!bUseFauxPhysicsContraints"))
	float Min = 0.0;

	UPROPERTY(EditAnywhere, meta = (EditCondition = "!bUseFauxPhysicsContraints"))
	float Max = 1.0;

	UPROPERTY()
	float Alpha = 0.0;

	UFauxPhysicsAxisRotateComponent FauxPhysicsAxisRotateComponent;
	UFauxPhysicsTranslateComponent FauxPhysicsTranslateComponent;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		if (FauxPhysicsOwner == nullptr)
			FauxPhysicsOwner = Owner;

		if (FauxPhysicsOwner != nullptr)
		{
			if (AlphaFromAxis == EAlphaFromContraints::Rotation)
				FauxPhysicsAxisRotateComponent = UFauxPhysicsAxisRotateComponent::Get(FauxPhysicsOwner);
			else
				FauxPhysicsTranslateComponent = UFauxPhysicsTranslateComponent::Get(FauxPhysicsOwner);
		}

		// Rotation
		if (FauxPhysicsAxisRotateComponent != nullptr)
		{
			if (bUseFauxPhysicsContraints)
			{
				Min = FauxPhysicsAxisRotateComponent.ConstrainAngleMin;
				Max = FauxPhysicsAxisRotateComponent.ConstrainAngleMax;
			}
		}

		// Translation
		if (FauxPhysicsTranslateComponent != nullptr)
		{
			if (bUseFauxPhysicsContraints)
			{
				switch (AlphaFromAxis)
				{
					case EAlphaFromContraints::TranslationX:
						Min = FauxPhysicsTranslateComponent.MinX;
						Max = FauxPhysicsTranslateComponent.MaxX;
						break;

					case EAlphaFromContraints::TranslationY:
						Min = FauxPhysicsTranslateComponent.MinY;
						Max = FauxPhysicsTranslateComponent.MaxY;
						break;

					case EAlphaFromContraints::TranslationZ:
						Min = FauxPhysicsTranslateComponent.MinZ;
						Max = FauxPhysicsTranslateComponent.MaxZ;
						break;

					case EAlphaFromContraints::Rotation:
						check(false, "USanctuaryFauxAlphaComponent Used EAlphaFromContraints::Rotation for its translation constraint");
						break;
				}
			}
		}
	}

	UFUNCTION(BlueprintOverride)
	void Tick(float DeltaSeconds)
	{

	}

	UFUNCTION(BlueprintPure)
	float GetCurrentAlpha()
	{
		if (FauxPhysicsAxisRotateComponent != nullptr)
			Alpha = Math::GetMappedRangeValueClamped(FVector2D(Min, Max), FVector2D(0.0, 1.0), Math::RadiansToDegrees(FauxPhysicsAxisRotateComponent.CurrentRotation));

		if (FauxPhysicsTranslateComponent != nullptr)
		{
			float Translation = 0.0;

			switch (AlphaFromAxis)
			{
				case EAlphaFromContraints::TranslationX:
					Translation = (FauxPhysicsTranslateComponent.RelativeLocation - FauxPhysicsTranslateComponent.SpringParentOffset).X;
					break;

				case EAlphaFromContraints::TranslationY:
					Translation = (FauxPhysicsTranslateComponent.RelativeLocation - FauxPhysicsTranslateComponent.SpringParentOffset).Y;
					break;

				case EAlphaFromContraints::TranslationZ:
					Translation = (FauxPhysicsTranslateComponent.RelativeLocation - FauxPhysicsTranslateComponent.SpringParentOffset).Z;
					break;
				case EAlphaFromContraints::Rotation:
					check(false, "USanctuaryFauxAlphaComponent Used EAlphaFromContraints::Rotation for its translation constraint");
					break;
			}

			Alpha = Math::GetMappedRangeValueClamped(FVector2D(Min, Max), FVector2D(0.0, 1.0), Translation);
		}
	
		return Alpha;
	}
}