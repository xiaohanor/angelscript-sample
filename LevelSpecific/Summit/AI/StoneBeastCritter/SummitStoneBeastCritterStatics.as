namespace SummitStoneBeastCritter
{
	USummitStoneBeastCritterAttackManagerComponent GetManager(AHazeActor Target)
	{
		return USummitStoneBeastCritterAttackManagerComponent::GetOrCreate(Target);
	}
}