enum EIslandForceFieldEffectType
{
	EnemyRed,
	EnemyBlue,
	EnemyBoth,
	PlayerRed,
	PlayerBlue,
	MAX
}

struct FIslandForceFieldDepletedParams
{
	UPROPERTY()
	FVector Location;

	UPROPERTY()
	EIslandForceFieldEffectType ForceFieldType;
}

struct FIslandForceFieldDepletedPlayerEventParams
{
	UPROPERTY()
	AHazePlayerCharacter DepletedByPlayer;

	UPROPERTY()
	AHazeActor ForceFieldOwner;	

	UPROPERTY()
	FVector Location;

	UPROPERTY()
	EIslandForceFieldEffectType ForceFieldType;
}

struct FIslandForceFieldImpactParams
{
	UPROPERTY()
	FVector Location;
	
	UPROPERTY()
	EIslandForceFieldEffectType ForceFieldType;
}

struct FIslandForceSwitchTypeParams
{
	UPROPERTY()
	AHazeActor ForceFieldOwner;
	
	UPROPERTY()
	EIslandForceFieldType NewForceFieldType;
}

UCLASS(Abstract)
class UIslandForceFieldEffectHandler : UHazeEffectEventHandler
{	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldDepleted(FIslandForceFieldDepletedParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldImpact(FIslandForceFieldImpactParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldSwitchedType(FIslandForceSwitchTypeParams Params) {}
}


UCLASS(Abstract)
class UIslandForceFieldPlayerEffectHandler : UHazeEffectEventHandler
{	
	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldDepleted(FIslandForceFieldDepletedPlayerEventParams Params) {}

	UFUNCTION(BlueprintEvent, Meta = (AutoCreateBPNode))
	void OnForceFieldSwitchedType(FIslandForceSwitchTypeParams Params) {}
}