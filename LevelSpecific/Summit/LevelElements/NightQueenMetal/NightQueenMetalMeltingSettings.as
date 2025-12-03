class UNightQueenMetalMeltingSettings : UHazeComposableSettings
{
	/* How much damage the metal can take before it fully melts
		Damage is set in the TeenDragonAcidSpraySeettings */
	UPROPERTY()
	float Health = 1.0;

	UPROPERTY()
	bool bOneShotMetal = true;

	// Speed at which the metal melts towards its set alpha
	UPROPERTY()
	float MeltingSpeed = 1.75;

	// Speed of metal regrowing
	UPROPERTY()
	float RegrowthSpeed = 0.4;

	// Speed at which the metal dissolves after fully melting
	UPROPERTY()
	float DissolvingSpeed = 1.0;

	// Speed at which the metal dissolves after fully melting
	UPROPERTY()
	float UnDissolvingSpeed = 0.45;

	// Delay before it starts to undissolve after dissolve started
	UPROPERTY()
	float UnDissolveDelay = 4.5;

	// Amount melted at start of undissolving
	UPROPERTY()
	float MeltedAmountAtUnDissolveStart = 0.0;

	// Whether or not the metal should check if the player is inside the volume before starting to regrow
	// False means that the player dies when the collision is turned on
	UPROPERTY()
	bool bDontRegrowWhenPlayerInArea = true;

	// Threshold at which the collision gets switched off while metal is dissolving
	// 0 switches off when it starts dissolving
	// 1 switches off when it is finished dissolving
	UPROPERTY()
	float DissolveCollisionThreshold = 0.5;

	// Time axel ; 0 - 1 percentage metal missing
	// Value axel ; delay time before regrowth starts
	UPROPERTY()
	FRuntimeFloatCurve RegrowthDelay;
	default RegrowthDelay.AddDefaultKey(0, 0.1);
	default RegrowthDelay.AddDefaultKey(1, 2.25);

	// Overrides the melting vfx that is played when acid hits a meltable target
	UPROPERTY(Category = VFX)
	UNiagaraSystem VFXOverride_Melting;

	UPROPERTY(Category = VFX)
	bool bDisableFinisher = false;

	// Overrides the finisher VFX that is played when the mesh is dissolved
	UPROPERTY(Category = VFX)
	UNiagaraSystem VFXOverride_MeltFinisher;

	// TEMP hack to prevent the WPO, that the shader does, from stopping
	UPROPERTY(Category = VFX)
	bool bSaturateMeltAlpha = false;
}