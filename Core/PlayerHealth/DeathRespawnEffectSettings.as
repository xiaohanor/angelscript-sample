class UDeathRespawnEffectSettings : UHazeComposableSettings
{
	//Death particles to use
	UPROPERTY(Category = "Death Particles")
	UNiagaraSystem DeathParticleEffect;
	//Death particles override to use
	UPROPERTY(Category = "Death Particles")
	UNiagaraSystem DeathParticleEffectOverride;
	//Overall force applied to particles
	UPROPERTY(Category = "Death Particles")
	float ParticleForceMultiplier = 2.0;
	//Multiply size of sphere for force influence - force is based on distance from location within the sphere, so force will be stronger as well the large the sphere is
	UPROPERTY(Category = "Death Particles")
	float ParticleSphereSizeMultiplier = 1.5;
	//Drag on particles
	UPROPERTY(Category = "Death Particles")
	float ParticleDrag = 1.1;
	//How far the location that force is applied from is set
	UPROPERTY(Category = "Death Particles")
	float ParticleUnitOffsetMultiplier = 0.75;
	UPROPERTY(Category = "Death Particles")
	FVector PlayerCenterLocationOffset = FVector(0.0);

	//Override the "default" value of camera stop duration
	UPROPERTY(Category = "Death Camera")
	float DefaultCameraStopDuration = 0.6;
	//You can give the death cam a blendout duration, which means that it won't snap the camera on respawn. Use this with care please
	UPROPERTY(Category = "Death Camera")
	float DefaultCameraBlendOutDuration = 0.0;

#if EDITOR
	UPROPERTY(Category = "Death Particles")
	bool bDebugDrawCenterPositionOnDeath = false;
#endif

	UPROPERTY(Category = "Respawn Particles")
	UNiagaraSystem RespawnParticleEffect;
	UPROPERTY(Category = "Respawn Material")
	UMaterialInterface RespawnOverlayMaterial;
	// When finding meshes to use the respawn material on, we by default ignore any translucent or additive materials.
	UPROPERTY(Category = "Respawn Material")
	bool bAllowTranslucentMaterials = false;

	//Overlay niagara damage effect on player
	UPROPERTY(Category = "Damage Material")
	UNiagaraSystem OverlayDamageEffect;
	//Overlay material for when the player is flashing 
	UPROPERTY(Category = "Damage Material")
	UMaterialInterface OverlayDamageMaterial;
	//Override default one shot impact effect on being damaged. Will not be used if damage type isn't "generic". Then it will always use from the asset instead
	UPROPERTY(Category = "Damage Effect")
	TPerPlayer<UNiagaraSystem> DefaultRecieveDamageEffect;

	UPROPERTY(Category = "Damage Animations")
	bool bPlayAdditiveDamageAnimations = true;
}