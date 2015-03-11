-- This program needs to be named init.lua or called from init.lua in the ESP-8266 module.
-- Every 60-seconds it will look for a file named "success.txt" on your web server.
-- If it is not found or the server is offline, it will send a SMS message to the phone number you provided.
-- It will send a SMS message when the server comes back online.


--wifi.setmode(wifi.STATION)
--wifi.sta.config("NETGEAR","")
--wifi.sta.connect()

-- Need to fill in the URL to monitor.
-- Need to fill in the user name and password for the SMTP mail server.
-- added a comment
-- Need to fill in the phone number (and mail-to-text service) to send SMS message to.

function SMS(message)
	c=0
	q=""
	tmr.alarm(1, 1000, 1, function()
		if c==0 then
			conn=net.createConnection(net.TCP, 0) 
			conn:connect(80,'tycho.usno.navy.mil')
			conn:on("connection",function(conn, p)
				conn:send("GET /timer.html / HTTP/1.1\r\nAccept: */*\r\n User-Agent: Mozilla/4.0 (compatible; esp8266 Lua;)\r\n\r\n") 
			end)
			conn:on("receive", function(conn, p)
				ss=string.find(p,"Universal Time")
				if ss>=0 then
					q = string.sub(p,ss+19, ss+43)
					print(t..":"..q)
					c=1
				end
				conn:close()
			end)
		else	
			tmr.stop(1)
			i = 1
			
			conn=net.createConnection(net.TCP, 0)
			conn:connect(25,"mail.neo.rr.com")			
			conn:on("receive", function(conn,p)
				if(i==1 and string.match(p,"220")) then conn:send("EHLO SMon\r\n") end
				if(i==2 and string.match(p,"AUTH LOGIN")) then conn:send("AUTH LOGIN\r\n") end
				if(i==3 and string.match(p,"334 VXNlcm5hbWU6")) then conn:send("xyzzy\r\n") end -- calculate the user
				if(i==4 and string.match(p,"334 UGFzc3dvcmQ6")) then conn:send("xyzzy\r\n") end  -- calculate the password
				if(i==5 and string.match(p,"235")) then conn:send("MAIL FROM: <email@neo.rr.com>\r\n") end
				if(i==6) then conn:send("RCPT TO: <5555555555@vtext.com>\r\n") end
				if(i==7) then conn:send("DATA\r\n") end
				if(i==8) then
					if newstate==0 then
						m="(Up"
					else
						m="(Down"
					end
					conn:send('From: "yourname" <yourname@neo.rr.com>\r\n')
					conn:send("To: <5555555555@vtext.com>\r\nSubject: "..message.."\r\nMIME-Version: 1.0\r\nDate: "..q.."\r\nContent-Type: text/plain; charset=iso-8859-1\r\nContent-Transfer-Encoding: quoted-printable\r\n\r\n")
					conn:send(q..m.."time: "..s..")\r\n.\r\n")
				end
				if(i==9  and string.match(p,"250")) then conn:send("quit\r\n") end
				i=i+1
			end)
			conn:on("disconnection", function() conn=nil end)
		end
	end)
end

LoopCnt=0
t=0
oldstate=-1

tmr.alarm(0, 1000, 1, function() 
	LoopCnt=LoopCnt+1
	if LoopCnt==60 then
		print(t..":Testing Server")
		conn=net.createConnection(net.TCP, 0) 
		conn:connect(80,'url.com')  -- server URL to monitor
		conn:on("connection",function(conn, p)
			conn:send("GET /success.txt / HTTP/1.1\r\nHost: URL.COM\r\nAccept: */*\r\n User-Agent: Mozilla/4.0 (compatible; Lua;)\r\n\r\n") 
		end)

		conn:on("receive", function(conn, p)
			doit=0
			newstate=0
			if string.find(p,"404 Not Found") then
				y=" Offline"
			else
				y=" Online"
				newstate=1
			end
			if oldstate==newstate then
				x="Still"
			else
				x="Went"
				s=t
				t=0
				doit=1
				print("Reset Timer")
			end
			if doit==1 then
				SMS("Server "..x..y)
			end
			oldstate=newstate
		end)
		conn:close()
		LoopCnt=0
		t=t+1
	else
		print(t..":"..LoopCnt)
	end
end)
