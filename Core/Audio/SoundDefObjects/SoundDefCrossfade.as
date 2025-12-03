// class USoundDefCrossfade : USoundDefCrossfadeObject
// {
// 	UFUNCTION(BlueprintOverride)
// 	void EvaluateLayers(const float InPosition)
// 	{
// 		for(FHazeCrossfadeLayer& Layer : Layers)
// 		{			
// 			CalculateLayerAlpha(InPosition, Layer);				
// 		}

// 		for(FHazeCrossfadeLayer& Layer : Layers)
// 		{
// 			if(IsOverlapping(InPosition, Layer))
// 			{
// 				if(!Layer.bHasEntered || !bIsLooping)
// 				{
// 					TriggerOnLayerEnter(Layer);
// 				}
// 			}
// 			else if(Layer.bHasEntered && bIsLooping)
// 			{
// 				TriggerOnLayerExit(Layer);
// 			}
// 		}		
// 	}

// 	void CalculateLayerAlpha(const float InPosition, FHazeCrossfadeLayer& Layer)
// 	{
// 		if(!IsOverlapping(InPosition, Layer))
// 			return;

// 		FHazeCrossfadeLayer Previous;
// 		GetPrevious(Layer, Previous);

// 		const bool bCrossfading = IsLayerValid(Previous) && IsOverlapping(InPosition, Previous);

// 		// First check if current layer is in a crossfade with a previous layer. If so, update both this and the previous layer's alpha-value
// 		if(bCrossfading)
// 		{
// 			float FadeInLerpAlpha = Math::GetPercentageBetween(Layer.ConfigData.StartPosition, Previous.ConfigData.StopPosition, InPosition);
// 			const float ThisLayerAlpha = Math::EaseIn(0.0, 1.0, FadeInLerpAlpha, Layer.ConfigData.FadeInCurvePower);			

// 			float FadeOutLerpAlpha = Math::GetPercentageBetween(Layer.ConfigData.StartPosition, Previous.ConfigData.StopPosition, InPosition);
// 			const float PreviousLayerAlpha = Math::EaseOut(1.0, 0.0, FadeOutLerpAlpha, Previous.ConfigData.FadeOutCurvePower);

// 			SetLayerAlpha(Layer.LayerId, ThisLayerAlpha);
// 			SetLayerAlpha(Previous.LayerId, PreviousLayerAlpha);
// 		}
// 		else 
// 		{
// 			// We are not crossfading with a previous layer, check for the next layer
// 			FHazeCrossfadeLayer Next;
// 			GetNext(Layer, Next);

// 			// If there's no next, check if we should apply the global fade out on this layer based on the current position
// 			if(!IsLayerValid(Next) && ShouldFadeOut(InPosition))
// 			{			
// 				const float FadeOutLerpAlpha = Math::GetPercentageBetween(FadeOutStart, MaxRange, InPosition);
// 				const float LastLayerFadeOutAlpha= Math::EaseOut(1.0, 0.0, FadeOutLerpAlpha, Previous.ConfigData.FadeOutCurvePower);

// 				SetLayerAlpha(Layer.LayerId, LastLayerFadeOutAlpha);				
// 			}
// 			else if(ShouldFadeIn(InPosition))
// 			{
// 				// We are within the range of the global fade in, apply it in alpha calculations
// 				const float FadeInLerpAlpha = Math::GetPercentageBetween(0, FadeInLength, InPosition);
// 				const float LayerFadeInAlpha= Math::EaseIn(0.0, 1.0, FadeInLerpAlpha, Layer.ConfigData.FadeOutCurvePower);

// 				SetLayerAlpha(Layer.LayerId, LayerFadeInAlpha);
// 			}
// 			else
// 			{
// 				// We are not in a crossfade, and we are not overlapping with global fade in or fade out. Alpha is simply 1
// 				SetLayerAlpha(Layer.LayerId, 1.0);
// 			}
// 		}			
// 	}

// 	bool IsOverlapping(const float InPosition, FHazeCrossfadeLayer& Layer)
// 	{
// 		return Layer.ConfigData.StartPosition <= InPosition
// 			&& Layer.ConfigData.StopPosition >= InPosition;
// 	}

// 	bool IsLayerValid(FHazeCrossfadeLayer& Layer)
// 	{
// 		return Layer.LayerId >= 0;
// 	}

// 	bool ShouldFadeIn(const float InPosition)
// 	{
// 		return FadeInLength > 0 && InPosition <= FadeInLength;
// 	}

// 	bool ShouldFadeOut(const float InPosition)
// 	{
// 		return FadeOutStart > 0 && InPosition >= FadeOutStart;
// 	}
// }