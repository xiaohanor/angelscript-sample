struct FDentistToothApplyRagdollSettings
{
	UPROPERTY(EditAnywhere)
	bool bApplyRagdoll = true;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bApplyRagdoll"))
	float AngularImpulseMultiplier = 0.1;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bApplyRagdoll"))
	bool bOverrideRagdollDuration = false;

	UPROPERTY(EditAnywhere, Meta = (EditCondition = "bApplyRagdoll && bOverrideRagdollDuration", EditConditionHides))
	float RagdollDuration = 1.0;
}

event void FDentistToothOnImpulseFromObstacle(AActor Obstacle, FVector Impulse, FDentistToothApplyRagdollSettings RagdollSettings);

UCLASS(NotBlueprintable)
class UDentistToothImpulseResponseComponent : UActorComponent
{
	UPROPERTY()
	FDentistToothOnImpulseFromObstacle OnImpulseFromObstacle;
};