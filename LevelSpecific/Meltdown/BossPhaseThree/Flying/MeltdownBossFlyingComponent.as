class UMeltdownBossFlyingComponent : UActorComponent
{
	bool bIsFlying = false;
	AActor CenterPoint;
	float Distance;

	FVector2D MovementBlendSpaceValue;
	bool bIsDashing = false;
	FVector2D DashDirection;

	float KnockbackImpulse;
};

namespace MeltdownBossFlying
{

UFUNCTION(Category = "Meltdown Boss | Flying")
void StartFlying(AHazePlayerCharacter Player, AActor CenterPoint, float Distance)
{
	auto Comp = UMeltdownBossFlyingComponent::Get(Player);
	Comp.bIsFlying = true;
	Comp.CenterPoint = CenterPoint;
	Comp.Distance = Distance;
}

UFUNCTION(Category = "Meltdown Boss | Flying")
void StopFlying(AHazePlayerCharacter Player)
{
	auto Comp = UMeltdownBossFlyingComponent::Get(Player);
	Comp.bIsFlying = false;
}

}