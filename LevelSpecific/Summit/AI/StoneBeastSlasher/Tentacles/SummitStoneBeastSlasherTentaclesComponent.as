struct FSummitStoneBeastSlasherTentacle
{
	UNiagaraComponent Effect;
	FVector LocalOrigin;
	FHazeAcceleratedVector AccNear;
	FHazeAcceleratedVector AccFar;
	FHazeAcceleratedVector AccEnd;
	float UndulateOffset;
	bool bBehaviourOverride;
}

class USummitStoneBeastSlasherTentaclesComponent : USceneComponent
{
	UPROPERTY()
	UNiagaraSystem TentacleFX;

	TArray<FSummitStoneBeastSlasherTentacle> Tentacles;
};

class USummitStoneBeastSlasherTentacleDecalComponent : UDecalComponent
{
	default SetHiddenInGame(true);
}

class USummitStoneBeastSlasherTentacleSettings : UHazeComposableSettings
{
	// Number of tentacles. Block and unblock companion tentacle capability to update this.
	UPROPERTY(Category = "Tentacles")
	int NumTentacles = 1;

	// Distance from actor origin to tentacle origin
	UPROPERTY(Category = "Tentacles")
	float TentacleOriginRadius = 0.0;

	// Resting length of tentacle
	UPROPERTY(Category = "Tentacles")
	float TentacleLength = 400.0;

	UPROPERTY(Category = "Tentacles")
	float NearFraction = 0.3;
	UPROPERTY(Category = "Tentacles")
	float NearStiffness = 200.0;
	UPROPERTY(Category = "Tentacles")
	float NearDamping = 0.9;

	UPROPERTY(Category = "Tentacles")
	float FarFraction = 0.6;
	UPROPERTY(Category = "Tentacles")
	float FarStiffness = 6.0;
	UPROPERTY(Category = "Tentacles")
	float FarDamping = 0.3;

	UPROPERTY(Category = "Tentacles")
	float EndStiffness = 4.0;
	UPROPERTY(Category = "Tentacles")
	float EndDamping = 0.2;
};

