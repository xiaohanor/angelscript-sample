
class USummitMeltSettings : UHazeComposableSettings
{
	UPROPERTY()
	float MaxHealth = 1.0;

	// At what health fraction does the mesh start WPO melt?
	UPROPERTY()
	float MeltStartFraction = 1.0;

	// how long it takes to dissolve the material in time
	UPROPERTY()
	float DissolveDuration = 0.5;

	UPROPERTY()
	float StayMeltedDuration = 3;

	UPROPERTY()
	float StayDissolvedDuration = 5;

	UPROPERTY()
	float AdditionalStayDissolvedRate = 0.15;

	UPROPERTY()
	float AdditionalStayDissolvedMaxDuration = 3;

	UPROPERTY()
	float RestoreDuration = 1;

	//////////////////////////////////////////////////////////
	// Start Boss fixes

	// everything is dependent on this value. By clamping it we'll control everything else.
	UPROPERTY()
	float MinHealth = 0.0;

	UPROPERTY(Category = Hacks)
	float SphereMask_DissolvingSpeed = 1.0;

	UPROPERTY(Category = Hacks)
	float SphereMask_MeltingSpeed = 1.0;

	UPROPERTY(Category = Hacks)
	UNiagaraSystem OverrideImpactVFXAsset_SkelMesh;

	UPROPERTY(Category = Hacks)
	UNiagaraSystem OverrideImpactVFXAsset_StaticMesh;

	// END Boss Fixes
	//////////////////////////////////////////////////////////

};