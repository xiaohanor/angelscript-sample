class UAudioDebugMusic : UAudioDebugTypeHandler
{
	EHazeAudioDebugType Type() override { return EHazeAudioDebugType::Music; }
	
	FString GetTitle() override
	{
		return "Music";
	}

	void Draw(UAudioDebugManager DebugManager, const FHazeImmediateSectionHandle& Section) override
	{
		auto MusicManager = UHazeAudioMusicManager::Get();

		for (const auto& MusicInstance: MusicManager.GetMusicEvents())
		{
			Section.Text(f"Switch: {MusicInstance.MusicSwitch.Name}").Color(FLinearColor::Green);
			Section.Text(f"	MediaPlaying: {MusicInstance.MusicSegment}").Color(FLinearColor::Purple);
			Section.Text(f"	State: {MusicInstance.CurrentState}").Color(FLinearColor::Yellow);

			const auto& MusicData = MusicInstance.MarkerData;
			// Let the user know when the next chord will arrive.
			FString TimeRemainingText = "";
			auto ChordTimeleft = MusicData.NextTimeMarkerChange - Time::GetAudioTimeSeconds();
			if (ChordTimeleft > 0)
				TimeRemainingText = f"- In {ChordTimeleft} sec";

			Section.Text(f"	Chord Previous: {MusicData.Previous.Label}").Color(FLinearColor::LucBlue);
			Section.Text(f"	Chord Current:  {MusicData.Current.Label}").Color(FLinearColor::LucBlue);
			Section.Text(f"	Chord Next: 	{MusicData.Next.Label}{TimeRemainingText}").Color(FLinearColor::LucBlue);

			for (const auto& Stinger: MusicInstance.Stingers)
			{
				Section.Text(f"	Stinger: {Stinger.MusicSegment}").Color(FLinearColor::Yellow);
				float DurationLeft = Stinger.EndTime - Time::GetAudioTimeSeconds();
				Section.Text(f"		Estimated timeleft: {DurationLeft}").Color(FLinearColor::Red);
			}

			for (const auto& Playlist: MusicInstance.Playlists)
			{
				Section.Text(f"	Playlist: {Playlist.Playlist}").Color(FLinearColor::Green);
				float DurationLeft = Playlist.EndTime - Time::GetAudioTimeSeconds();
				Section.Text(f"	Estimated timeleft: {DurationLeft}").Color(FLinearColor::Red);
				Section.Text(f"		Current: {Playlist.Current}").Color(FLinearColor::Yellow);
				Section.Text(f"		Next: {Playlist.Next}").Color(FLinearColor::Yellow);
			}
		}
	}
}