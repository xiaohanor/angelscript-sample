// Generic melee enemy behaviour
class UBasicBehaviourMeleeCompoundCapability : UHazeCompoundCapability
{
	default NetworkMode = EHazeCapabilityNetworkMode::Crumb;
	default CapabilityTags.Add(BasicAITags::CompoundBehaviour);

	// Always active
	UFUNCTION(BlueprintOverride)
	bool ShouldActivate() const
	{
		return true;
	}

	UFUNCTION(BlueprintOverride)
	UHazeCompoundNode GenerateCompound()
	{
		return 	UHazeCompoundSelector()
					// Stunned
					.Try(UHazeCompoundRunAll()
						.Add(UBasicKnockdownBehaviour())
						.Add(UBasicHurtReactionBehaviour())
					)
					// Combat
					.Try(UHazeCompoundRunAll()
						.Add(UHazeCompoundSequence()
							.Then(UHazeCompoundStatePicker()
								.State(UBasicMeleeAttackBehaviour(SubTagAIMeleeCombat::FinisherAttack, 2.0, 0.3))
								.State(UBasicMeleeAttackBehaviour(SubTagAIMeleeCombat::DualAttack, 1.2, 0.5))
								.State(UBasicMeleeAttackBehaviour(SubTagAIMeleeCombat::SingleAttack, 1.5, 1.0))
							)
							.Then(UBasicFallBackBehaviour())
						)
						.Add(UBasicCircleAdvanceBehaviour())
						.Add(UBasicChaseBehaviour())
						.Add(UBasicGentlemanCircleBehaviour())
						.Add(UBasicTrackTargetBehaviour())
						.Add(UBasicRaiseAlarmBehaviour())
					)
					// Idle
					.Try(UHazeCompoundRunAll()
						.Add(UBasicFindTargetBehaviour())
						.Add(UBasicScenepointEntranceBehaviour())
						.Add(UBasicRoamBehaviour())
					);
	}
}

