
class UHazeEditorWorldLinkPositionComponent : USceneComponent
{
	/**
	 * This function needs to be called from the actors containing the 'EditorWorldLinkPositionComponent'
	 */
	#if EDITOR
	void OnActorModifiedInEditor()
	{
		auto LinkComp = UHazeWorldLinkComponent::Get(Owner);

		if (LinkComp != nullptr &&
			LinkComp.LinkedActor.IsValid() &&
			LinkComp.LinkedActor.Get() != Owner)
		{
			auto OtherActor = LinkComp.LinkedActor.Get();
			auto OtherSyncComp = UHazeEditorWorldLinkPositionComponent::Get(OtherActor);
			
			if (OtherSyncComp != nullptr)
			{
				auto Anchor = WorldLink::GetClosestAnchor(WorldLocation);
				auto OtherAnchor = WorldLink::GetOppositeAnchor(Anchor);

				if (Anchor != nullptr && OtherAnchor != nullptr)
				{
					const FVector Offset = Anchor.ActorLocation - WorldLocation;
					OtherActor.ActorLocation = OtherAnchor.ActorLocation - Offset;
				}
			}
		}

		// Finally link up the worlds
		LinkComp.LinkUpWorlds();
	}
	#endif
}