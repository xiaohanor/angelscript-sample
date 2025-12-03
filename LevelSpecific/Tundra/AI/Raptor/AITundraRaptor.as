UCLASS(Abstract, meta = (DefaultActorLabel = "TundraRaptor"))
class ATundraRaptor : ABasicAIFlyingCharacter
{
	default MoveToComp.DefaultSettings = BasicAIFlyingPathfindingMoveToSettings;
	default CapabilityComp.DefaultCapabilities.Add(n"TundraRaptorBehaviourCompoundCapability");

	UPROPERTY(DefaultComponent)
	UBasicAIHealthBarComponent HealthBarComp;

	UPROPERTY(DefaultComponent)
	UTundraRaptorTargetComp RaptorTargetComp;

	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		Super::BeginPlay();
		JoinTeam(TundraRaptorTags::TundraRaptorTeam);
		UBasicAIHealthBarSettings::SetHealthBarVisibility(this, EBasicAIHealthBarVisibility::AlwaysShow, this);
	}

	UFUNCTION(BlueprintOverride)
	void EndPlay(EEndPlayReason EndPlayReason)
	{
		LeaveTeam(TundraRaptorTags::TundraRaptorTeam);
	}
}

namespace TundraRaptorTags
{
	const FName TundraRaptorTeam = n"TundraRaptorTeam";
	const FName TundraRaptorPointTeam = n"TundraRaptorPointTeam";
	const FName TundraRaptorCircle = n"TundraRaptorCircle";
}