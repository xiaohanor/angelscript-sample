// Trivia: Esca is the name of the "lightbulb" on anglerfishies
class ULightSeekerEmissiveEscaCapability : UHazeCapability
{
	default TickGroup = EHazeTickGroup::Gameplay;
	ULightSeekerEmissiveEscaComponent EscaComp;
	ALightSeeker LightSeeker;

	UFUNCTION(BlueprintOverride)
	void Setup()
	{
		LightSeeker = Cast<ALightSeeker>(Owner);
		EscaComp = ULightSeekerEmissiveEscaComponent::GetOrCreate(Owner);
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		if (!ShouldHaveEmissiveEsca())
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	bool ShouldDeactivate() const
	{
		if (ShouldHaveEmissiveEsca())
			return false;
		if (!Math::IsNearlyEqual(EscaComp.AccEmissiveEsca.Value, 0.0, KINDA_SMALL_NUMBER))
			return false;
		return true;
	}

	UFUNCTION(BlueprintOverride)
	void OnActivated()
	{
	}

	UFUNCTION(BlueprintOverride)
	void OnDeactivated()
	{
		EscaComp.EmissiveEscaDynamicMaterial.SetVectorParameterValue(n"EmissiveTint", FLinearColor::Black);
	}

	bool ShouldHaveEmissiveEsca() const
	{
		if (LightSeeker.bIsInTrance)
			return true;
		if (LightSeeker.bIsChasing)
			return true;
		return false;
	}

	UFUNCTION(BlueprintOverride)
	void TickActive(float DeltaTime)
	{
		if (ShouldHaveEmissiveEsca())
			EscaComp.AccEmissiveEsca.AccelerateToWithStop(1.0, 2.0, DeltaTime, 0.01);
		else
			EscaComp.AccEmissiveEsca.AccelerateToWithStop(0.0, 5.0, DeltaTime, 0.01);
		EscaComp.EmissiveEscaDynamicMaterial.SetVectorParameterValue(n"EmissiveTint", FLinearColor::White * EscaComp.AccEmissiveEsca.Value);
	}
};