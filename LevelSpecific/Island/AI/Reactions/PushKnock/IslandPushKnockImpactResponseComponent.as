event void FIslandPushKnockImpactResponseSignature(AHazeCharacter ImpactInstigator);

class UIslandPushKnockTargetImpactResponseComponent : UActorComponent
{
	UFUNCTION(BlueprintOverride)
	void BeginPlay()
	{
		AHazeActor HazeOwner = Cast<AHazeActor>(Owner);
		HazeOwner.JoinTeam(PushKnockTags::PushKnockTargetsTeam);
	}

	UPROPERTY(Category = "Impact")
	FIslandPushKnockImpactResponseSignature OnImpact;

	void OnApplyImpact(AHazeCharacter FromCharacter)
	{
		OnImpact.Broadcast(FromCharacter);
	}
}

class UIslandPushKnockSelfImpactResponseComponent : UActorComponent
{
	UPROPERTY(Category = "Impact")
	FIslandPushKnockImpactResponseSignature OnImpact;

	void OnApplyImpact(AHazeCharacter FromCharacter)
	{
		OnImpact.Broadcast(FromCharacter);
	}
}

namespace PushKnockTags
{
	const FName PushKnockTargetsTeam = n"PushKnockTargetsTeam";
}